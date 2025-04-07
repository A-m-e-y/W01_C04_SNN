module tb_shift_test;
    parameter INPUT_WIDTH = 8;              // Width of input current
    parameter POTENTIAL_WIDTH = 16;         // Width of membrane potential
    parameter LEAK_FACTOR = 4;             // Leak rate (power of 2 for division)

    logic signed [POTENTIAL_WIDTH-1:0] membrane_potential;
    logic signed [INPUT_WIDTH-1:0] current_in;
    logic signed [POTENTIAL_WIDTH-1:0] extended_current;
    logic signed [POTENTIAL_WIDTH-1:0] leak_term;
    
    initial begin
        current_in = 73; // Example input current
        membrane_potential = -460;
        #10; // Wait for 10 time units

        extended_current = {{(POTENTIAL_WIDTH-INPUT_WIDTH){current_in[INPUT_WIDTH-1]}}, current_in};
        #10; // Wait for 10 time units
        
        // Calculate leak term (ensure sign is preserved)
        leak_term = membrane_potential >>> LEAK_FACTOR;
        #10; // Wait for 10 time units
        
        // Update membrane potential with controlled arithmetic
        membrane_potential <= membrane_potential + extended_current - leak_term;

//        membrane_potential <= membrane_potential + 
//                {{(POTENTIAL_WIDTH-INPUT_WIDTH){current_in[INPUT_WIDTH-1]}}, current_in} - 
//                (membrane_potential >>> LEAK_FACTOR);
        #10; // Wait for 10 time units
        $display("membrane_potential value: %d", membrane_potential);
        $finish;
    end
endmodule
