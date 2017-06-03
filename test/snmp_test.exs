defmodule SNMP.Test do
  use ExUnit.Case, async: false
  doctest SNMP

  @moduletag :integrated

  @sysname_oid [1,3,6,1,2,1,1,5,0]
  @sysname_value {@sysname_oid, :"OCTET STRING", 'some value'}

  setup_all do
    SNMP.start
  end

  defp get_credential(:none, :none) do
    SNMP.credential [
      :v3,
      :no_auth_no_priv,
      "usr-none-none",
    ]
  end
  defp get_credential(auth, :none)
      when auth in [:md5, :sha]
  do
    SNMP.credential [
      :v3,
      :auth_no_priv,
      "usr-#{Atom.to_string auth}-none",
      auth,
      "authkey1",
    ]
  end
  defp get_credential(auth, priv)
      when auth in [:md5, :sha]
       and priv in [:des, :aes]
  do
    SNMP.credential [
      :v3,
      :auth_priv,
      "usr-#{Atom.to_string auth}-#{Atom.to_string priv}",
      auth,
      "authkey1",
      priv,
      "privkey1",
    ]
  end

  defp get_sysname(credential) do
    snmp_agent = "104.236.166.95"
    engine_id  = <<0x80004fb805636c6f75644dab22cc::14*8>>

    # Update engine boots, time
    _ = SNMP.get([], snmp_agent, credential, engine_id: engine_id)

    SNMP.get(@sysname_oid, snmp_agent, credential, engine_id: engine_id)
  end

  test "SNMPv3 GET noAuthNoPriv" do
    result =
      :none
      |> get_credential(:none)
      |> get_sysname

    assert result == [@sysname_value]
  end

  test "SNMPv3 GET authNoPriv" do
    for auth <- [:md5, :sha] do
      credential = get_credential(auth, :none)

      assert get_sysname(credential) == [@sysname_value]
    end
  end

  test "SNMPv3 GET authPriv" do
    for auth <- [:md5, :sha], priv <- [:des] do
      credential = get_credential(auth, priv)

      assert get_sysname(credential) == [@sysname_value]
    end
  end
end
