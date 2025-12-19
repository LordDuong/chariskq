`timescale 1ns / 1ps

module key2ascii_tb;

    reg letter_case;
    reg [7:0] scan_code;
    wire [7:0] ascii_code;
    
    // Instantiate key2ascii module
    key2ascii dut (
        .letter_case(letter_case),
        .scan_code(scan_code),
        .ascii_code(ascii_code)
    );
    
    initial begin
        $display("====== Key to ASCII Conversion Test ======\n");
        $display("Scan Code\tLetter Case\tASCII Code\tCharacter");
        
        // Test lowercase letters
        letter_case = 1'b0;
        
        // Test 'a' (0x1C)
        scan_code = 8'h1C;
        #10;
        $display("0x%h\t\t0 (lower)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        // Test 'h' (0x33)
        scan_code = 8'h33;
        #10;
        $display("0x%h\t\t0 (lower)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        // Test '0' (0x45)
        scan_code = 8'h45;
        #10;
        $display("0x%h\t\t0 (lower)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        // Test space (0x29)
        scan_code = 8'h29;
        #10;
        $display("0x%h\t\t0 (lower)\t0x%h\t\t'(space)'", scan_code, ascii_code);
        
        // Test uppercase letters
        letter_case = 1'b1;
        
        // Test 'A' (0x1C with uppercase)
        scan_code = 8'h1C;
        #10;
        $display("0x%h\t\t1 (upper)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        // Test 'H' (0x33 with uppercase)
        scan_code = 8'h33;
        #10;
        $display("0x%h\t\t1 (upper)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        // Test ')' (0x45 with uppercase, which is 0)
        scan_code = 8'h45;
        #10;
        $display("0x%h\t\t1 (upper)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        // Test '!' (0x16 with uppercase)
        scan_code = 8'h16;
        #10;
        $display("0x%h\t\t1 (upper)\t0x%h\t\t'%c'", scan_code, ascii_code, ascii_code);
        
        $display("\n====== Test Complete ======");
        $finish;
    end
    
endmodule