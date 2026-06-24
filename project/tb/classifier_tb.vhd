-- Testbench for classifier.vhd.
--
-- This testbench validates project-level constraints.

entity classifier_tb is
end entity;

architecture bench of classifier_tb is

    component classifier
        port (
            clk          : in  bit;
            reset        : in  bit;
            SW           : in  bit_vector(3 downto 0);
            load_inputs  : in  bit;
            compute_mac  : in  bit;
            z            : out integer range -128 to 127;
            class_result : out bit
        );
    end component;

    constant Z_MIN : integer := -128;
    constant Z_MAX : integer := 127;

    signal CLK_TB          : bit := '0';
    signal RESET_TB        : bit := '0';
    signal SW_TB           : bit_vector(3 downto 0) := "0000";
    signal LOAD_INPUTS_TB  : bit := '0';
    signal COMPUTE_MAC_TB  : bit := '0';
    signal Z_TB            : integer range -128 to 127;
    signal CLASS_RESULT_TB : bit;

begin

    DUT: classifier
        port map (
            clk          => CLK_TB,
            reset        => RESET_TB,
            SW           => SW_TB,
            load_inputs  => LOAD_INPUTS_TB,
            compute_mac  => COMPUTE_MAC_TB,
            z            => Z_TB,
            class_result => CLASS_RESULT_TB
        );

    clock_process: process
    begin
        CLK_TB <= '0';
        wait for 5 ns;

        CLK_TB <= '1';
        wait for 5 ns;
    end process;

    stimulus: process
        variable reference_score : integer;
        variable reference_class : bit;
        variable hold_score      : integer;
        variable hold_class      : bit;
    begin

        -- Reset must clear the visible classifier outputs.
        -- Other inputs are active/nonzero to check reset priority.
        RESET_TB <= '1';
        LOAD_INPUTS_TB <= '1';
        COMPUTE_MAC_TB <= '1';
        SW_TB <= "1111";
        wait for 12 ns;

        assert Z_TB = 0
            report "Reset failed: z should be 0"
            severity failure;

        assert CLASS_RESULT_TB = '0'
            report "Reset failed: class_result should be 0"
            severity failure;

        RESET_TB <= '0';
        LOAD_INPUTS_TB <= '0';
        COMPUTE_MAC_TB <= '0';
        SW_TB <= "0000";
        wait for 8 ns;

        -- Without load_inputs or compute_mac, changing SW must not change outputs.
        hold_score := Z_TB;
        hold_class := CLASS_RESULT_TB;
        SW_TB <= "1111";
        wait for 10 ns;

        assert Z_TB = hold_score
            report "Idle failed: z changed without compute_mac"
            severity failure;

        assert CLASS_RESULT_TB = hold_class
            report "Idle failed: class_result changed without compute_mac"
            severity failure;

        -- All 16 switch patterns must be accepted.
        for i in 0 to 15 loop

            case i is
                when 0 =>
                    SW_TB <= "0000";
                when 1 =>
                    SW_TB <= "0001";
                when 2 =>
                    SW_TB <= "0010";
                when 3 =>
                    SW_TB <= "0011";
                when 4 =>
                    SW_TB <= "0100";
                when 5 =>
                    SW_TB <= "0101";
                when 6 =>
                    SW_TB <= "0110";
                when 7 =>
                    SW_TB <= "0111";
                when 8 =>
                    SW_TB <= "1000";
                when 9 =>
                    SW_TB <= "1001";
                when 10 =>
                    SW_TB <= "1010";
                when 11 =>
                    SW_TB <= "1011";
                when 12 =>
                    SW_TB <= "1100";
                when 13 =>
                    SW_TB <= "1101";
                when 14 =>
                    SW_TB <= "1110";
                when others =>
                    SW_TB <= "1111";
            end case;

            LOAD_INPUTS_TB <= '1';
            wait for 10 ns;

            LOAD_INPUTS_TB <= '0';
            COMPUTE_MAC_TB <= '1';
            wait for 10 ns;

            COMPUTE_MAC_TB <= '0';
            wait for 1 ns;

            if Z_TB >= 0 then
                assert CLASS_RESULT_TB = '1'
                    report "Activation failed: z >= 0 should produce class_result = 1"
                    severity failure;
            else
                assert CLASS_RESULT_TB = '0'
                    report "Activation failed: z < 0 should produce class_result = 0"
                    severity failure;
            end if;

        end loop;

        -- Input latch check.
        -- First compute a reference result for SW = "0010".
        -- Then load the same SW value again, change live SW before compute_mac,
        -- and verify that compute_mac still uses the stored input value.
        SW_TB <= "0010";
        LOAD_INPUTS_TB <= '1';
        wait for 10 ns;

        LOAD_INPUTS_TB <= '0';
        COMPUTE_MAC_TB <= '1';
        wait for 10 ns;

        COMPUTE_MAC_TB <= '0';
        wait for 1 ns;

        reference_score := Z_TB;
        reference_class := CLASS_RESULT_TB;

        SW_TB <= "0010";
        LOAD_INPUTS_TB <= '1';
        wait for 10 ns;

        LOAD_INPUTS_TB <= '0';
        SW_TB <= "0100";
        COMPUTE_MAC_TB <= '1';
        wait for 10 ns;

        COMPUTE_MAC_TB <= '0';
        wait for 1 ns;

        assert Z_TB = reference_score
            report "Input latch failed: compute used live SW instead of stored input"
            severity failure;

        assert CLASS_RESULT_TB = reference_class
            report "Input latch failed: class_result changed after live SW changed"
            severity failure;

        wait;

    end process;

end architecture;
