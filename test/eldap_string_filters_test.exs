defmodule EldapStringFiltersTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias EldapStringFilters

  @test_suite [
    %{
      input: "(cn=*)",
      expected: :eldap.present('cn'),
      desc: "CN presence filter"
    },
    %{
      input: "(cn=Babs Jensen)",
      expected: :eldap.equalityMatch('cn', 'Babs Jensen'),
      desc: "simple CN match"
    },
    %{
      input: "(!(cn=Tim Howes))",
      expected: :eldap.equalityMatch('cn', 'Tim Howes') |> :eldap.not(),
      desc: "simple negation"
    },
    %{
      input: "(&(objectClass=Person)(|(sn=Jensen)(cn=Babs J*)))",
      expected:
        [
          :eldap.equalityMatch('objectClass', 'Person'),
          [
            :eldap.equalityMatch('sn', 'Jensen'),
            :eldap.substrings('cn', initial: 'Babs J')
          ]
          |> :eldap.or()
        ]
        |> :eldap.and(),
      desc: "simple match ANDed with alternative between simple match or substring"
    },
    %{
      input: "(o=univ*of*mich)",
      expected: :eldap.substrings('o', initial: 'univ', any: 'of', final: 'mich'),
      desc: "simple substring match"
    },
    %{
      input: "(o=som*wh*ove*bow*)",
      expected: :eldap.substrings('o', initial: 'som', any: 'wh', any: 'ove', any: 'bow'),
      desc: "substring match with multiple parts"
    },
    %{
      input: "(cn=John*)",
      expected: :eldap.substrings('cn', initial: 'John'),
      desc: "substring match with single initial part"
    },
    %{
      input: "(cn=*John*)",
      expected: :eldap.substrings('cn', any: 'John'),
      desc: "substring match with single any part"
    },
    %{
      input: "(cn=*John*Doe*)",
      expected: :eldap.substrings('cn', any: 'John', any: 'Doe'),
      desc: "substring match with multiple any parts"
    },
    %{
      input: "(cn=*Doe)",
      expected: :eldap.substrings('cn', final: 'Doe'),
      desc: "substring match with single final part"
    },
    %{
      input: "(seeAlso=)",
      expected: :eldap.equalityMatch('seeAlso', ''),
      desc: "simple match to the null string"
    },
    %{
      desc: "match 2 attributes (AND)",
      input: "(&(objectClass=person)(objectClass=user))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectClass', 'person'),
          :eldap.equalityMatch('objectClass', 'user')
        ])
    },
    %{
      desc: "matches alternative attributes (OR)",
      input: "(|(objectClass=person)(objectClass=user))",
      expected:
        :eldap.or([
          :eldap.equalityMatch('objectClass', 'person'),
          :eldap.equalityMatch('objectClass', 'user')
        ])
    },
    %{
      desc: "attribute and wildcard match",
      input: "(&(objectClass=user)(cn=*Marketing*))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectClass', 'user'),
          :eldap.substrings('cn', any: 'Marketing')
        ])
    },
    %{
      desc: "matches 3 attributes",
      input: "(&(objectClass=user)(objectClass=top)(objectClass=person))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectClass', 'user'),
          :eldap.equalityMatch('objectClass', 'top'),
          :eldap.equalityMatch('objectClass', 'person')
        ])
    },
    %{
      desc: "match part of a DN",
      input: "(&(objectClass=group)(|(ou:dn:=Chicago)(ou:dn:=Miami)))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectClass', 'group'),
          :eldap.or([
            :eldap.extensibleMatch('Chicago',
              dnAttributes: true,
              type: 'ou'
            ),
            :eldap.extensibleMatch('Miami',
              dnAttributes: true,
              type: 'ou'
            )
          ])
        ])
    },
    %{
      desc: "exclude entities which match an expression",
      input: "(&(objectClass=group)(&(ou:dn:=Chicago)(!(ou:dn:=Wrigleyville))))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectClass', 'group'),
          :eldap.and([
            :eldap.extensibleMatch('Chicago',
              dnAttributes: true,
              type: 'ou'
            ),
            :eldap.not(
              :eldap.extensibleMatch('Wrigleyville',
                dnAttributes: true,
                type: 'ou'
              )
            )
          ])
        ])
    },
    %{
      desc: "search users in the 'CaptainPlanet' group",
      input:
        "(&(objectCategory=Person)(sAMAccountName=*)(memberOf=cn=CaptainPlanet,ou=users,dc=company,dc=com))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectCategory', 'Person'),
          :eldap.present('sAMAccountName'),
          :eldap.equalityMatch('memberOf', 'cn=CaptainPlanet,ou=users,dc=company,dc=com')
        ])
    },
    %{
      desc: "search for users that are a member of this group, either directly or via nesting",
      input:
        "(&(objectCategory=Person)(sAMAccountName=*)(memberOf:1.2.840.113556.1.4.1941:=cn=CaptainPlanet,ou=users,dc=company,dc=com))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectCategory', 'Person'),
          :eldap.present('sAMAccountName'),
          :eldap.extensibleMatch('cn=CaptainPlanet,ou=users,dc=company,dc=com',
            dnAttributes: false,
            type: 'memberOf',
            matchingRule: '1.2.840.113556.1.4.1941'
          )
        ])
    },
    %{
      desc:
        "search for users who are a member of any or all the 4 groups (fire, wind, water, earth)",
      input:
        "(&(objectCategory=Person)(sAMAccountName=*)(|(memberOf=cn=fire,ou=users,dc=company,dc=com)(memberOf=cn=wind,ou=users,dc=company,dc=com)(memberOf=cn=water,ou=users,dc=company,dc=com)(memberOf=cn=earth,ou=users,dc=company,dc=com)))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectCategory', 'Person'),
          :eldap.present('sAMAccountName'),
          :eldap.or([
            :eldap.equalityMatch('memberOf', 'cn=fire,ou=users,dc=company,dc=com'),
            :eldap.equalityMatch('memberOf', 'cn=wind,ou=users,dc=company,dc=com'),
            :eldap.equalityMatch('memberOf', 'cn=water,ou=users,dc=company,dc=com'),
            :eldap.equalityMatch('memberOf', 'cn=earth,ou=users,dc=company,dc=com')
          ])
        ])
    },
    %{
      desc: "search for users that have an email address",
      input: "(&(objectCategory=Person)(sAMAccountName=*)(mail=*))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectCategory', 'Person'),
          :eldap.present('sAMAccountName'),
          :eldap.present('mail')
        ])
    },
    %{
      desc:
        "search for users that have an email address and are a member of any or all of the groups in the filter",
      input:
        "(&(objectCategory=Person)(sAMAccountName=*)(mail=*)(|(memberOf=cn=fire,OU=Super Company,dc=xxxx,dc=com)(memberOf=cn=wind,OU=Super Company,dc=xxxx,dc=com)(memberOf=cn=water,OU=Super Company,dc=xxxx,dc=com)(memberOf=cn=earth,OU=Super Company,dc=xxxx,dc=com)))",
      expected:
        :eldap.and([
          :eldap.equalityMatch('objectCategory', 'Person'),
          :eldap.present('sAMAccountName'),
          :eldap.present('mail'),
          :eldap.or([
            :eldap.equalityMatch('memberOf', 'cn=fire,OU=Super Company,dc=xxxx,dc=com'),
            :eldap.equalityMatch('memberOf', 'cn=wind,OU=Super Company,dc=xxxx,dc=com'),
            :eldap.equalityMatch('memberOf', 'cn=water,OU=Super Company,dc=xxxx,dc=com'),
            :eldap.equalityMatch('memberOf', 'cn=earth,OU=Super Company,dc=xxxx,dc=com')
          ])
        ])
    },
    %{
      desc: "A deeply nested filter (well, this is real)",
      input:
        "(&(|" <>
          "(sn=*ratto*)(givenName=*ratto*)(o=*ratto*)(mobile=*ratto*)(facsimileTelephoneNumber=*ratto*)" <>
          "(telephoneNumber=*ratto*)(vsfast=ratto*)(ou=*ratto*)(roomNumber=*ratto*)(departmentNumber=*ratto*)" <>
          "(employeeNumber=*ratto*)(title=*ratto*)(mail=*ratto*)(description=*ratto*)(employeeType=*ratto*))" <>
          "(|(vsctgroup=vs-public)(&(vsctowner=admin@192.168.1.186)(vsctgroup=vs-personal))(vsctgroup=pippo)))",
      expected:
        :eldap.and([
          :eldap.or([
            :eldap.substrings('sn', any: 'ratto'),
            :eldap.substrings('givenName', any: 'ratto'),
            :eldap.substrings('o', any: 'ratto'),
            :eldap.substrings('mobile', any: 'ratto'),
            :eldap.substrings('facsimileTelephoneNumber', any: 'ratto'),
            :eldap.substrings('telephoneNumber', any: 'ratto'),
            :eldap.substrings('vsfast', initial: 'ratto'),
            :eldap.substrings('ou', any: 'ratto'),
            :eldap.substrings('roomNumber', any: 'ratto'),
            :eldap.substrings('departmentNumber', any: 'ratto'),
            :eldap.substrings('employeeNumber', any: 'ratto'),
            :eldap.substrings('title', any: 'ratto'),
            :eldap.substrings('mail', any: 'ratto'),
            :eldap.substrings('description', any: 'ratto'),
            :eldap.substrings('employeeType', any: 'ratto')
          ]),
          :eldap.or([
            :eldap.equalityMatch('vsctgroup', 'vs-public'),
            :eldap.and([
              :eldap.equalityMatch('vsctowner', 'admin@192.168.1.186'),
              :eldap.equalityMatch('vsctgroup', 'vs-personal')
            ]),
            :eldap.equalityMatch('vsctgroup', 'pippo')
          ])
        ])
    }
  ]

  @test_suite
  |> Enum.each(fn %{input: input, expected: expected, desc: desc} ->
    expected = Macro.escape(expected)

    test desc do
      assert {:ok, unquote(expected)} = EldapStringFilters.parse(unquote(input))
    end
  end)
end
