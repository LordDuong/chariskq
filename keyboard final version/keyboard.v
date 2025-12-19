module keyboard
    (
	input wire clk, reset,
        input wire ps2d, ps2c,               // ps2 data and clock lines
        output wire [7:0] scan_code,         // scan_code received from keyboard to process
        output wire scan_code_ready,         // signal to outer control system to sample scan_code
        output wire letter_case_out          // output to determine if scan code is converted to lower or upper ascii code for a key
    );
	
    // constant declarations
    localparam  BREAK    = 8'hf0, // break code
                SHIFT1   = 8'h12, // first shift scan
                SHIFT2   = 8'h59, // second shift scan
                CAPS     = 8'h58; // caps lock

    // FSM symbolic states
    localparam [2:0] lowercase          = 3'b000, // idle, process lower case letters
                     ignore_break       = 3'b001, // ignore repeated scan code after break code -F0- reeived
                     shift              = 3'b010, // process uppercase letters for shift key held
                     ignore_shift_break = 3'b011, // check scan code after F0, either idle or go back to uppercase
		     capslock           = 3'b100, // process uppercase letter after capslock button pressed
		     ignore_caps_break  = 3'b101; // check scan code after F0, either ignore repeat, or decrement caps_num
                     
               
    // internal signal declarations
    reg [2:0] state_reg, state_next;           // FSM state register and next state logic
    wire [7:0] scan_out;                       // scan code received from keyboard
    reg got_code_tick;                         // asserted to write current scan code received to FIFO
    wire scan_done_tick;                       // asserted to signal that ps2_rx has received a scan code
    reg letter_case;                           // 0 for lower case, 1 for uppercase, outputed to use when converting scan code to ascii
    reg [7:0] shift_type_reg, shift_type_next; // register to hold scan code for either of the shift keys or caps lock
    reg [1:0] caps_num_reg, caps_num_next;     // keeps track of number of capslock scan codes received in capslock state (3 before going back to lowecase state)
   
    // instantiate ps2 receiver
    ps2_rx ps2_rx_unit (.clk(clk), .reset(reset), .rx_en(1'b1), .ps2d(ps2d), .ps2c(ps2c), .rx_done_tick(scan_done_tick), .rx_data(scan_out));
	
	// FSM stat, shift_type, caps_num register 
    always @(posedge clk, posedge reset)
        if (reset)
			begin
			state_reg      <= lowercase;
			shift_type_reg <= 0;
			caps_num_reg   <= 0;
			end
        else
			begin    
                        state_reg      <= state_next;
			shift_type_reg <= shift_type_next;
			caps_num_reg   <= caps_num_next;
			end
			
    //FSM next state logic
    always @*
        begin
       
        // defaults
        got_code_tick   = 1'b0;
	letter_case     = 1'b0;
	caps_num_next   = caps_num_reg;
        shift_type_next = shift_type_reg;
        state_next      = state_reg;
       
        case(state_reg)
			
	    // state to process lowercase key strokes, go to uppercase state to process shift/capslock
            lowercase:
				if (scan_done_tick)
					if (scan_out == SHIFT1 || scan_out == SHIFT2)
						begin
						shift_type_next = scan_out;
						state_next = shift;
						end
					else if (scan_out == CAPS)
						begin
						shift_type_next = scan_out;
						state_next = capslock;
						end
					else if (scan_out == BREAK)
						state_next = ignore_break;
					else
						got_code_tick = 1'b1;
						
			// ignore the scan code after the break code F0
            ignore_break:
				if (scan_done_tick)
					state_next = lowercase;
					
			// process scan codes when shift key is held
            shift:
				if (scan_done_tick)
					if (scan_out == BREAK)
						begin
						state_next = ignore_shift_break;
						end
					else
						begin
						got_code_tick = 1'b1;
						letter_case = 1'b1;
						end
						
			// after F0 in shift state, check if the break code is for shift or another key
            ignore_shift_break:
				if (scan_done_tick)
					if (scan_out == shift_type_reg)
						state_next = lowercase;
					else
						state_next = shift;
						
			// process scan codes when capslock is on
            capslock:
				if (scan_done_tick)
					if (scan_out == CAPS)
						state_next = ignore_caps_break;
					else if (scan_out == BREAK)
						state_next = ignore_break;
					else
						begin
						got_code_tick = 1'b1;
						letter_case = 1'b1;
						end
						
			// after F0 in capslock state, check if the break code is for capslock or another key
            ignore_caps_break:
				if (scan_done_tick)
					if (scan_out == CAPS)
						begin
						caps_num_next = caps_num_reg + 1;
						if (caps_num_reg == 2)
							begin
							caps_num_next = 0;
							state_next = lowercase;
							end
						else
							state_next = capslock;
						end
					else
						state_next = capslock;
        endcase
        end
        
    assign scan_code = scan_out;
    assign scan_code_ready = got_code_tick;
    assign letter_case_out = letter_case;
    
endmodule