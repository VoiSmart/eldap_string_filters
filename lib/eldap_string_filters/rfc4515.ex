defmodule EldapStringFilters.RFC4515 do
  @moduledoc false

  use AbnfParsec,
    parse: :filter,
    unbox: [
      "andoperator",
      "attributedescription",
      "attributetype",
      "descr",
      "DOT",
      "equal",
      "extensible",
      "filter",
      "filtercomp",
      "filterlist",
      "item",
      "keychar",
      "keystring",
      "LDIGIT",
      "leadkeychar",
      "normal",
      "notoperator",
      "number",
      "numericoid",
      "oid",
      "oroperator",
      "present",
      "simple",
      "substring",
      "UTF1SUBSET",
      "valueencoding"
    ],
    unwrap: [
      "assertionvalue",
      "attr",
      "dnattrs",
      "matchingrule"
    ],
    ignore: [
      "COLON",
      "AMPERSAND",
      "EXCLAMATION",
      "options",
      "VERTBAR",
      "LPAREN",
      "RPAREN"
    ],
    transform: %{
      "andoperator" => {:reduce, {EldapStringFilters.RFC4515, :and_operator, []}},
      "assertionvalue" => {:reduce, {List, :to_string, []}},
      "attributetype" => {:reduce, {List, :to_string, []}},
      "dnattrs" => {:replace, true},
      "extensible" => {:reduce, {EldapStringFilters.RFC4515, :extensible_filter, []}},
      "matchingrule" => {:reduce, {List, :to_string, []}},
      "notoperator" => {:reduce, {EldapStringFilters.RFC4515, :not_operator, []}},
      "oroperator" => {:reduce, {EldapStringFilters.RFC4515, :or_operator, []}},
      "present" => {:reduce, {EldapStringFilters.RFC4515, :present_filter, []}},
      "simple" => {:reduce, {EldapStringFilters.RFC4515, :simple_filter, []}},
      "substring" => {:reduce, {EldapStringFilters.RFC4515, :substring_filter, []}}
    },
    debug: false,
    skip: ["item"],
    abnf_file: "abnf/rfc4515.abnf"

  # Redefining the abnf parsec function for the :item key
  # because nible_parsec does not really backtrack and abnf
  # grammar is not clear about precedence.
  # So adding a lookahead here is order to prevent overlaps.
  defparsec(
    :item,
    choice([
      parsec(:present) |> lookahead(ascii_char(')')),
      parsec(:substring),
      parsec(:extensible),
      parsec(:simple)
    ])
  )

  def and_operator(filters) do
    :eldap.and(filters)
  end

  def or_operator(filters) do
    :eldap.or(filters)
  end

  def not_operator([filter]) do
    :eldap.not(filter)
  end

  def present_filter(opts) do
    attr = Keyword.fetch!(opts, :attr)
    :eldap.present(to_charlist(attr))
  end

  def substring_filter(opts) do
    attr = Keyword.fetch!(opts, :attr) |> to_charlist()

    subs =
      []
      |> handle_subinitial(opts)
      |> handle_subany(opts)
      |> handle_subfinal(opts)

    :eldap.substrings(attr, Enum.reverse(subs))
  end

  def simple_filter(opts) do
    attr = Keyword.fetch!(opts, :attr) |> to_charlist()
    filt = Keyword.fetch!(opts, :filtertype)
    value = Keyword.fetch!(opts, :assertionvalue) |> to_charlist()

    case handle_filtertype(filt) do
      :approx ->
        :eldap.approxMatch(attr, value)

      :equals ->
        :eldap.equalityMatch(attr, value)

      :greaterorequal ->
        :eldap.greaterOrEqual(attr, value)

      :lessorequal ->
        :eldap.lessOrEqual(attr, value)
    end
  end

  def extensible_filter(opts) do
    dnattrs = Keyword.get(opts, :dnattrs, false)
    value = Keyword.fetch!(opts, :assertionvalue) |> to_charlist()
    eldap_opts = [dnAttributes: dnattrs]

    eldap_opts =
      case Keyword.get(opts, :attr) do
        nil -> eldap_opts
        v -> Keyword.put(eldap_opts, :type, to_charlist(v))
      end

    eldap_opts =
      case Keyword.get(opts, :matchingrule) do
        nil -> eldap_opts
        v -> Keyword.put(eldap_opts, :matchingRule, to_charlist(v))
      end

    :eldap.extensibleMatch(value, eldap_opts)
    |> patch_extensible_match()
  end

  # see https://github.com/erlang/otp/pull/5615
  def patch_extensible_match({:extensibleMatch, {record, rule, type, value, 'TRUE'}}) do
    {:extensibleMatch, {record, rule, type, value, true}}
  end

  def patch_extensible_match({:extensibleMatch, {record, rule, type, value, 'FALSE'}}) do
    {:extensibleMatch, {record, rule, type, value, false}}
  end

  def patch_extensible_match(record), do: record

  defp handle_filtertype(approx: _), do: :approx
  defp handle_filtertype(equals: _), do: :equals
  defp handle_filtertype(greaterorequal: _), do: :greaterorequal
  defp handle_filtertype(lessorequal: _), do: :lessorequal

  defp handle_subinitial(subs, opts) do
    case Keyword.get(opts, :initial) do
      nil ->
        subs

      v ->
        case Keyword.get(v, :assertionvalue) do
          empty when empty in [nil, ""] -> subs
          value -> [{:initial, to_charlist(value)} | subs]
        end
    end
  end

  defp handle_subany(subs, opts) do
    case Keyword.get(opts, :any) do
      nil ->
        subs

      v ->
        v
        |> Keyword.get_values(:assertionvalue)
        |> Enum.reduce(subs, fn
          nil, subs -> subs
          "", subs -> subs
          value, subs -> [{:any, to_charlist(value)} | subs]
        end)
    end
  end

  defp handle_subfinal(subs, opts) do
    case Keyword.get(opts, :final) do
      nil ->
        subs

      v ->
        case Keyword.get(v, :assertionvalue) do
          empty when empty in [nil, ""] -> subs
          value -> [{:final, to_charlist(value)} | subs]
        end
    end
  end
end
