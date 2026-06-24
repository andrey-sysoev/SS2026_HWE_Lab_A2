-- This block implements the control unit of the classifier system.
--
-- The control unit is a finite state machine (FSM).
-- It decides when the classifier should:
--   1. load the switch inputs
--   2. compute the weighted sum
--   3. mark the result as done


entity control_unit is
    port (
        -- Clock input from the FPGA board.
        -- The FSM changes state on the rising edge of this clock.
        clk         : in  bit;

        -- Reset input.
        -- When reset = '1', it has priority and forces the FSM to the IDLE state.
        reset       : in  bit;

        -- Start input from a button.
        -- When start = '1' in the IDLE state, one classification cycle begins.
        -- When start = '1' outside the IDLE state, it is ignoted. 
        start       : in  bit;

        -- Output control signal for the classifier input interface.
        -- When load_inputs = '1', the classifier stores SW into its internal x register.
        load_inputs : out bit;

        -- Output control signal for the classifier MAC block.
        -- When compute_mac = '1', the classifier calculates score z and class_result.
        compute_mac : out bit;

        -- Output status signal.
        -- When done = '1', the classification result is ready.
        done        : out bit
    );
end entity;

architecture behavior of control_unit is

    -- The FSM has four states.
    --
    -- IDLE:
    --   Wait for start = '1'.
    --
    -- LOAD:
    --   Activate load_inputs for one clock cycle.
    --
    -- MAC:
    --   Activate compute_mac for one clock cycle.
    --
    -- DONE_STATE:
    --   Activate done for one clock cycle.
    type state_type is (IDLE, LOAD, MAC, DONE_STATE);

    -- Current state of the FSM.
    signal state : state_type;

begin

    -- State register and next-state logic.
    --
    -- This process updates the state.
    -- reset is included in the sensitivity list because it is checked directly.
    -- clk is included because the state changes on the rising clock edge.
    process(clk, reset)
    begin

        -- Reset has priority.
        if reset = '1' then
            state <= IDLE;

        -- On the rising clock edge, move from one state to the next.
        elsif clk'event and clk = '1' then

            case state is

                -- In IDLE, the system waits until start is pressed.
                when IDLE =>
                    if start = '1' then
                        state <= LOAD;
                    else
                        state <= IDLE;
                    end if;

                -- LOAD lasts one clock cycle.
                -- After loading the input switches, go to MAC.
                when LOAD =>
                    state <= MAC;

                -- MAC lasts one clock cycle.
                -- After computing the weighted sum, go to DONE_STATE.
                when MAC =>
                    state <= DONE_STATE;

                -- DONE_STATE lasts one clock cycle.
                -- After that, return to IDLE and wait for another start.
                when DONE_STATE =>
                    state <= IDLE;

            end case;

        end if;
    end process;

    -- Output logic.
    --
    -- This process creates the control outputs from the current state.
    -- Only one main control output is active in each state.
    process(state)
    begin

        -- Default values to prevent unintended old output values.
        load_inputs <= '0';
        compute_mac <= '0';
        done <= '0';

        case state is

            -- Waiting state.
            -- No action is requested from the classifier.
            when IDLE =>
                load_inputs <= '0';
                compute_mac <= '0';
                done <= '0';

            -- Load state.
            -- Tell classifier to store SW into x.
            when LOAD =>
                load_inputs <= '1';
                compute_mac <= '0';
                done <= '0';

            -- MAC state.
            -- Tell classifier to calculate z and class_result.
            when MAC =>
                load_inputs <= '0';
                compute_mac <= '1';
                done <= '0';

            -- Done state.
            -- The result is ready for the output interface.
            when DONE_STATE =>
                load_inputs <= '0';
                compute_mac <= '0';
                done <= '1';

        end case;

    end process;

end architecture;
