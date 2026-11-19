library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu8 is
  port (
    a, b   : in  std_logic_vector(7 downto 0);
    op     : in  std_logic_vector(2 downto 0);
    result : out std_logic_vector(7 downto 0);
    zero   : out std_logic;
    cout   : out std_logic
  );
end alu8;

architecture Behavior of alu8 is
  component adder8 is
    port(
      Cin  : in  std_logic;
      X, Y : in  std_logic_vector(7 downto 0);
      S    : out std_logic_vector(7 downto 0);
      Cout : out std_logic
    );
  end component;

  signal add_s, sub_s : std_logic_vector(7 downto 0);
  signal add_c, sub_c : std_logic;

  -- For subtraction: A - B = A + (~B) + 1
  signal b_inv : std_logic_vector(7 downto 0);

  signal res_s : std_logic_vector(7 downto 0);
  signal cout_s: std_logic;
begin
  b_inv <= not b;

  ADDER_ADD : adder8 port map(
    Cin  => '0',
    X    => a,
    Y    => b,
    S    => add_s,
    Cout => add_c
  );

  ADDER_SUB : adder8 port map(
    Cin  => '1',
    X    => a,
    Y    => b_inv,
    S    => sub_s,
    Cout => sub_c
  );

  process(a, b, op, add_s, sub_s, add_c, sub_c)
  begin
    res_s  <= (others => '0');
    cout_s <= '0';

    case op is
      when "000" =>  -- ADD
        res_s  <= add_s;
        cout_s <= add_c;

      when "001" =>  -- SUB (A - B)
        res_s  <= sub_s;
        cout_s <= sub_c;  -- this is "no borrow" in 2's complement form

      when "010" =>  -- AND
        res_s <= a and b;

      when "011" =>  -- OR
        res_s <= a or b;

      when "100" =>  -- XOR
        res_s <= a xor b;

      when "101" =>  -- NOT A
        res_s <= not a;

      when "110" =>  -- SHIFT LEFT logical by 1
        res_s <= a(6 downto 0) & '0';

      when others => -- "111" SHIFT RIGHT logical by 1
        res_s <= '0' & a(7 downto 1);
    end case;
  end process;

  result <= res_s;
  cout   <= cout_s;

  -- zero flag
  zero <= '1' when res_s = x"00" else '0';
end Behavior;

