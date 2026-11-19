library ieee;
use ieee.std_logic_1164.all;

entity adder8 is
  port(
    Cin  : in  std_logic;
    X, Y : in  std_logic_vector(7 downto 0);
    S    : out std_logic_vector(7 downto 0);
    Cout : out std_logic
  );
end adder8;

architecture Behavior of adder8 is
  component adder4 is
    port(
      Cin  : in  std_logic;
      x, y : in  std_logic_vector(3 downto 0);
      s    : out std_logic_vector(3 downto 0);
      Cout : out std_logic
    );
  end component;

  signal c_mid : std_logic;
begin
  low4  : adder4 port map(Cin,   X(3 downto 0), Y(3 downto 0), S(3 downto 0), c_mid);
  high4 : adder4 port map(c_mid, X(7 downto 4), Y(7 downto 4), S(7 downto 4), Cout);
end Behavior;
