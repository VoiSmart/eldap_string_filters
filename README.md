[![CI](https://github.com/VoiSmart/eldap_string_filters/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/VoiSmart/eldap_string_filters/actions/workflows/ci.yml)

# EldapStringFilters

**An RFC4515 ldap string filter parser**

Given an ldap search text filter string in [RFC4515](https://tools.ietf.org/search/rfc4515) format, parses and converts
to a filter suitable to be used by [Eldap](https://www.erlang.org/doc/man/eldap).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eldap_string_filters` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eldap_string_filters, "~> 0.1.0"}
  ]
end
```

Docs can be found at [https://hexdocs.pm/eldap_string_filters](https://hexdocs.pm/eldap_string_filters).

## Usage
```elixir
iex> {:ok, filter} = EldapStringFilters.parse("(cn=Foo)")
{:ok, {:equalityMatch, {:AttributeValueAssertion, 'cn', 'Foo'}}}                                                                                                           

iex> {:ok, filter} = EldapStringFilters.parse("(&(|(ou:dn:=People)(:1.2.3.4:=Administration))(objectclass=inetorgperson)(sn=willeke))")
{:ok,
 {:and,
  [
    or: [
      extensibleMatch: {:MatchingRuleAssertion, :asn1_NOVALUE, 'ou', 'People',
       true},
      extensibleMatch: {:MatchingRuleAssertion, '1.2.3.4', :asn1_NOVALUE,
       'Administration', false}
    ],
    equalityMatch: {:AttributeValueAssertion, 'objectclass', 'inetorgperson'},
    equalityMatch: {:AttributeValueAssertion, 'sn', 'willeke'}
  ]}}
```