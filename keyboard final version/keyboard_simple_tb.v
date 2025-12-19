`timescale 1ns / 1ps

module keyboard_simple_tb;

    reg clk, reset;
    
    reg [7:0] mock_scan_data;
    reg mock_scan_done;
    
    reg [2:0] state_reg, state_next;
    reg [7:0] shift_type_reg, shift_type_next;
    reg [1:0] caps_num_reg, caps_num_next;
    reg got_code_tick;
    reg letter_case;
    
    localparam  BREAK    = 8'hf0,
                SHIFT1   = 8'h12,
                SHIFT2   = 8'h59,
                CAPS     = 8'h58;

    localparam [2:0] lowercase          = 3'b000,
                     ignore_break       = 3'b001,
                     shift              = 3'b010,
                     ignore_shift_break = 3'b011,
                     capslock           = 3'b100,
                     ignore_caps_break  = 3'b101;
    
    always #5 clk = ~clk;
    
    always @(posedge clk, posedge reset)
        if (reset) begin
            state_reg      <= lowercase;
            shift_type_reg <= 0;
            caps_num_reg   <= 0;
        end
        else begin
            state_reg      <= state_next;
            shift_type_reg <= shift_type_next;
            caps_num_reg   <= caps_num_next;
        end
    
    always @* begin
        got_code_tick   = 1'b0;
        letter_case     = 1'b0;
        caps_num_next   = caps_num_reg;
        shift_type_next = shift_type_reg;
        state_next      = state_reg;
        
        case(state_reg)
            lowercase:         
                if (mock_scan_done) begin
                    if (mock_scan_data == SHIFT1 || mock_scan_data == SHIFT2) begin
                        shift_type_next = mock_scan_data;
                        state_next = shift;
                    end
                    else if (mock_scan_data == CAPS) begin
                        shift_type_next = mock_scan_data;
                        state_next = capslock;
                    end
                    else if (mock_scan_data == BREAK)
                        state_next = ignore_break;
                    else
                        got_code_tick = 1'b1;
                end
                
            ignore_break:  
                if (mock_scan_done)
                    state_next = lowercase;
                    
            shift:  
                if (mock_scan_done) begin
                    if (mock_scan_data == BREAK)
                        state_next = ignore_shift_break;
                    else begin
                        got_code_tick = 1'b1;
                        letter_case = 1'b1;
                    end
                end
                
            ignore_shift_break:
                if (mock_scan_done) begin
                    if (mock_scan_data == shift_type_reg)
                        state_next = lowercase;
                    else
                        state_next = shift;
                end
                
            capslock:
                if (mock_scan_done) begin
                    if (mock_scan_data == CAPS)
                        state_next = ignore_caps_break;
                    else if (mock_scan_data == BREAK)
                        state_next = ignore_break;
                    else begin
                        got_code_tick = 1'b1;
                        letter_case = 1'b1;
                    end
                end
                
            ignore_caps_break:
                if (mock_scan_done) begin
                    if (mock_scan_data == CAPS) begin
                        caps_num_next = caps_num_reg + 1;
                        if (caps_num_reg == 2) begin
                            caps_num_next = 0;
                            state_next = lowercase;
                        end
                        else
                            state_next = capslock;
                    end
                    else
                        state_next = capslock;
                end
        endcase
    end
    
    task send_scan(input [7:0] code);
        begin
            mock_scan_data = code;
            mock_scan_done = 1'b1;
            #10;
            mock_scan_done = 1'b0;
            #10;
        end
    endtask
    
    initial begin
        clk = 0;
        reset = 0;
        mock_scan_done = 0;
        mock_scan_data = 0;
        
        $display("====== Keyboard FSM State Machine Test ======\n");
        $display("Scan Code\tCurrent State\tNext State\tCase");
        $display("==========================================================================");
        
        reset = 1;
        #100;
        reset = 0;
        #100;
        
        $display("\n[TEST 1] Send 'a' (0x1C) - Regular key in lowercase state");
        send_scan(8'h1C);
        #20;
        $display("0x1C\t\tlowercase(0)\tlowercase(0)\t%b", letter_case);
        
        $display("\n[TEST 2] Send 'h' (0x33) - Regular key in lowercase state");
        send_scan(8'h33);
        #20;
        $display("0x33\t\tlowercase(0)\tlowercase(0)\t%b", letter_case);
        
        $display("\n[TEST 3] Send SHIFT (0x12) - Modifier key, transition to shift state");
        send_scan(8'h12);
        #20;
        $display("0x12\t\tlowercase(0)\tshift(2)\t\t%b", letter_case);
        
        $display("\n[TEST 4] Send 'a' (0x1C) - Regular key with SHIFT held");
        send_scan(8'h1C);
        #20;
        $display("0x1C\t\tshift(2)\t\tshift(2)\t\t%b (uppercase=1)", letter_case);
        
        $display("\n[TEST 5] Send BREAK (0xF0) - Key release signal");
        send_scan(8'hF0);
        #20;
        $display("0xF0\t\tshift(2)\t\tignore_shift_break(3)\t%b", letter_case);
        
        $display("\n[TEST 6] Send SHIFT release (0x12) - Transition back to lowercase");
        send_scan(8'h12);
        #20;
        $display("0x12\t\tignore_shift_break(3)\tlowercase(0)\t%b", letter_case);
        
        $display("\n[TEST 7] Send 'h' (0x33) - Back to lowercase state");
        send_scan(8'h33);
        #20;
        $display("0x33\t\tlowercase(0)\tlowercase(0)\t%b", letter_case);
        
        $display("\n====== Test Complete ======\n");
        $display("State Encoding:");
        $display("  0 = lowercase");
        $display("  1 = ignore_break");
        $display("  2 = shift");
        $display("  3 = ignore_shift_break");
        $display("  4 = capslock");
        $display("  5 = ignore_caps_break\n");
        
        $finish;
    end
    
endmodule