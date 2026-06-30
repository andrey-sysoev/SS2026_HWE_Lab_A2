-- Testbench for control_unit.vhd.
--
-- Testbench validates system behavior:
--
--   reset = '1'
--       The control unit must command no action.
--       Therefore load_inputs, compute_mac, and done must all be '0'.
--
--   start = '0' before start is pressed
--       start has not been pressed yet.
--       Therefore the outputs must stay inactive.
--
--       If start stays '1' in LOAD, MAC, or DONE_STATE, it must be ignored.
--
--   start = '1' in IDLE
--       One classification cycle begins. The control unit must:
--         1. load the switch inputs
--         2. compute the MAC score
--         3. mark the result as done
--         4. return to inactive outputs
--
--   reset while active
--       Reset must have priority and immediately return all control outputs
--       to the inactive values.


entity control_unit_tb is
end entity;

architecture bench of control_unit_tb is

    component control_unit
        port (
            clk         : in  bit;
            reset       : in  bit;
            start       : in  bit;
            load_inputs : out bit;
            compute_mac : out bit;
            done        : out bit
        );
    end component;

    signal CLK_TB         : bit := '0';
    signal RESET_TB       : bit := '0';
    signal START_TB       : bit := '0';
    signal LOAD_INPUTS_TB : bit;
    signal COMPUTE_MAC_TB : bit;
    signal DONE_TB        : bit;

begin

    DUT: control_unit
        port map (
            clk         => CLK_TB,
            reset       => RESET_TB,
            start       => START_TB,
            load_inputs => LOAD_INPUTS_TB,
            compute_mac => COMPUTE_MAC_TB,
            done        => DONE_TB
        );

    -- Clock generator.
    --
    -- Period = 10 ns.
    -- The control unit updates on the rising clock edge.
    clock_process: process
    begin
        CLK_TB <= '0';
        wait for 5 ns;

        CLK_TB <= '1';
        wait for 5 ns;
    end process;

    stimulus: process
    begin

        -- RESET CHECK
        --
        -- Apply reset before doing any normal operation.
        -- Reset forces the FSM to IDLE.
        RESET_TB <= '1';
        START_TB <= '0';

        -- Wait a short simulation time so the asynchronous reset can affect
        -- the output signals before the assertions read them.
        wait for 1 ns;

        -- During reset, the expected control outputs are:
        --   load_inputs = '0'
        --   compute_mac = '0'
        --   done        = '0'
        assert LOAD_INPUTS_TB = '0'
            report "Reset failed: load_inputs must be 0 during reset"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "Reset failed: compute_mac must be 0 during reset"
            severity failure;

        assert DONE_TB = '0'
            report "Reset failed: done must be 0 during reset"
            severity failure;

        -- Keep reset active through one rising clock edge.
        -- This checks that a clock edge does not start any action while reset
        -- is still active.
        wait until CLK_TB = '1';
        wait for 1 ns;

        assert LOAD_INPUTS_TB = '0'
            report "Reset clock-edge failed: load_inputs must remain 0 while reset is active"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "Reset clock-edge failed: compute_mac must remain 0 while reset is active"
            severity failure;

        assert DONE_TB = '0'
            report "Reset clock-edge failed: done must remain 0 while reset is active"
            severity failure;

        -- IDLE CHECK BEFORE START
        --
        -- Release reset and keep start low before start is pressed.
        -- start has not been pressed yet.
        RESET_TB <= '0';
        START_TB <= '0';

        -- Wait for the next full rising edge after reset release.
        -- The following 1 ns delay is a simulation observation delay.
        -- It allows signal updates from the clock edge to become visible.
        wait until CLK_TB = '0';
        wait until CLK_TB = '1';
        wait for 1 ns;

        -- Before start is pressed, the control unit must stay inactive.
        assert LOAD_INPUTS_TB = '0'
            report "Idle failed: load_inputs must be 0 before start is pressed"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "Idle failed: compute_mac must be 0 before start is pressed"
            severity failure;

        assert DONE_TB = '0'
            report "Idle failed: done must be 0 before start is pressed"
            severity failure;

        -- START = '1' IN IDLE CHECK
        --
        -- Set start to 1 while the control unit is waiting in IDLE.
        -- This should begin one classification cycle.
        START_TB <= '1';

        -- On the next rising edge, start = '1' should move the FSM to LOAD.
        wait until CLK_TB = '0';
        wait until CLK_TB = '1';
        wait for 1 ns;

        -- LOAD CHECK
        --
        -- START_TB is still '1'.
        -- The expected control outputs are:
        --   load_inputs = '1'
        --   compute_mac = '0'
        --   done        = '0'
        assert LOAD_INPUTS_TB = '1'
            report "LOAD failed: load_inputs must be 1 after start is pressed"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "LOAD failed: compute_mac must be 0 while inputs are loading"
            severity failure;

        assert DONE_TB = '0'
            report "LOAD failed: done must be 0 while inputs are loading"
            severity failure;

        -- MAC CHECK
        --
        -- Wait for one clock cycle.
        --
        -- START_TB is still '1' here.
        -- Since the control unit is no longer in IDLE, start must be ignored.
        -- The expected control outputs are:
        --   load_inputs = '0'
        --   compute_mac = '1'
        --   done        = '0'
        wait until CLK_TB = '0';
        wait until CLK_TB = '1';
        wait for 1 ns;

        assert LOAD_INPUTS_TB = '0'
            report "MAC failed: load_inputs must be 0 during MAC computation"
            severity failure;

        assert COMPUTE_MAC_TB = '1'
            report "MAC failed: compute_mac must be 1 after input loading"
            severity failure;

        assert DONE_TB = '0'
            report "MAC failed: done must be 0 during MAC computation"
            severity failure;

        -- DONE CHECK
        --
        -- Wait for one more real clock cycle.
        --
        -- START_TB is still '1' here.
        -- Since the control unit is still not in IDLE, start must be ignored.
        -- The expected control outputs are:
        --   load_inputs = '0'
        --   compute_mac = '0'
        --   done        = '1'
        wait until CLK_TB = '0';
        wait until CLK_TB = '1';
        wait for 1 ns;

        assert LOAD_INPUTS_TB = '0'
            report "DONE_STATE failed: load_inputs must be 0 when result is done"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "DONE_STATE failed: compute_mac must be 0 when result is done"
            severity failure;

        assert DONE_TB = '1'
            report "DONE_STATE failed: done must be 1 after MAC computation"
            severity failure;

        -- RETURN TO IDLE CHECK
        --
        -- Wait for one more real clock cycle.
        --
        -- START_TB is still '1' before this rising edge.
        -- The control unit is in DONE_STATE, so start must be ignored.
        -- The expected control outputs are:
        --   load_inputs = '0'
        --   compute_mac = '0'
        --   done        = '0'
        wait until CLK_TB = '0';
        wait until CLK_TB = '1';
        wait for 1 ns;

        assert LOAD_INPUTS_TB = '0'
            report "Return failed: load_inputs must be 0 after done"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "Return failed: compute_mac must be 0 after done"
            severity failure;

        assert DONE_TB = '0'
            report "Return failed: done must return to 0 after one done action"
            severity failure;

        -- The control unit has returned to IDLE.
        -- Set START_TB to '0' before the next rising edge.
        -- Otherwise a new classification cycle would begin.
        START_TB <= '0';

        -- START = '1' AFTER RETURN TO IDLE CHECK
        --
        -- The FSM has returned to IDLE.
        -- When start = '1' again, the FSM should go to LOAD again.
        START_TB <= '1';

        wait until CLK_TB = '0';
        wait until CLK_TB = '1';
        wait for 1 ns;

        START_TB <= '0';

        assert LOAD_INPUTS_TB = '1'
            report "Second start failed: load_inputs must be 1 after start is pressed again"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "Second start failed: compute_mac must be 0 during second input loading"
            severity failure;

        assert DONE_TB = '0'
            report "Second start failed: done must be 0 during second input loading"
            severity failure;

        -- RESET WHILE ACTIVE
        --
        -- Apply reset while load_inputs is '1'.
        -- Reset has priority and must immediately make all control outputs 0.
        RESET_TB <= '1';
        wait for 1 ns;

        assert LOAD_INPUTS_TB = '0'
            report "Active reset failed: load_inputs must become 0 immediately after reset"
            severity failure;

        assert COMPUTE_MAC_TB = '0'
            report "Active reset failed: compute_mac must become 0 immediately after reset"
            severity failure;

        assert DONE_TB = '0'
            report "Active reset failed: done must become 0 immediately after reset"
            severity failure;

        wait;

    end process;

end architecture;
