module claude_lif_neuron_v1 #(
    parameter INPUT_WIDTH = 8,              // Width of input current
    parameter POTENTIAL_WIDTH = 16,         // Width of membrane potential
    parameter signed THRESHOLD = 16'sh7000,  // Firing threshold (now signed)
    parameter LEAK_FACTOR = 4,             // Leak rate (power of 2 for division)
    parameter REFRACTORY_PERIOD = 4         // Number of cycles to wait after spike
)(
    input  logic clk,                      // Clock input
    input  logic rst_n,                    // Active-low reset
    input  logic signed [INPUT_WIDTH-1:0] current_in,  // Input current
    output logic spike_out                 // Output spike
);

    // Internal registers
    logic signed [POTENTIAL_WIDTH-1:0] membrane_potential;
    logic [$clog2(REFRACTORY_PERIOD)-1:0] refractory_counter;
    logic in_refractory;
    
    // Move these declarations to module level for testbench visibility
    logic signed [POTENTIAL_WIDTH-1:0] extended_current;
    logic signed [POTENTIAL_WIDTH-1:0] leak_term;

    // Determine if in refractory period
    assign in_refractory = (refractory_counter != 0);

    // Main sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_potential <= '0;
            refractory_counter <= '0;
            spike_out <= 1'b0;
        end else begin
            // Handle spike output and refractory period
            if (!in_refractory && 
                membrane_potential >= THRESHOLD && 
                membrane_potential < {1'b0, {(POTENTIAL_WIDTH-1){1'b1}}}) begin  // Check for positive value below max
                spike_out <= 1'b1;
                membrane_potential <= '0;
                refractory_counter <= REFRACTORY_PERIOD;
            end else begin
                spike_out <= 1'b0;
                
                // Update refractory counter
                if (in_refractory) begin
                    refractory_counter <= refractory_counter - 1;
                end

                // Update membrane potential if not in refractory period
                if (!in_refractory) begin
                    // Sign extend the input current
                    extended_current = {{(POTENTIAL_WIDTH-INPUT_WIDTH){current_in[INPUT_WIDTH-1]}}, current_in};
                    
                    // Calculate leak term (ensure sign is preserved)
                    leak_term = membrane_potential >>> LEAK_FACTOR;
                    
                    // Update membrane potential with controlled arithmetic
                    membrane_potential <= membrane_potential + extended_current - leak_term;
                end
            end
        end
    end

endmodule
