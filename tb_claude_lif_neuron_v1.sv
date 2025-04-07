module tb_claude_lif_neuron_v1;

    // Testbench parameters
    localparam CLK_PERIOD = 10;
    localparam INPUT_WIDTH = 8;
    localparam POTENTIAL_WIDTH = 16;
    localparam signed THRESHOLD = 16'd300;  // Match DUT threshold value and type
    localparam LEAK_FACTOR = 4;
    localparam REFRACTORY_PERIOD = 4;

    // Signals
    logic clk = 0;
    logic rst_n;
    logic signed [INPUT_WIDTH-1:0] current_in;
    logic spike_out;
    
    // Internal monitoring (connecting to DUT internals)
    logic signed [POTENTIAL_WIDTH-1:0] membrane_potential;
    logic [$clog2(REFRACTORY_PERIOD)-1:0] refractory_counter;
    
    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Instantiate DUT
    claude_lif_neuron_v1 #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
        .THRESHOLD(THRESHOLD),
        .LEAK_FACTOR(LEAK_FACTOR),
        .REFRACTORY_PERIOD(REFRACTORY_PERIOD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .current_in(current_in),
        .spike_out(spike_out)
    );
    
    // Connect to internal signals for monitoring
    assign membrane_potential = dut.membrane_potential;
    assign refractory_counter = dut.refractory_counter;
    
    // Test stimulus
    initial begin
        // Set up waveform dumping
        $dumpfile("lif_neuron_wave.vcd");
        $dumpvars(0, tb_claude_lif_neuron_v1);
        
        // Initialize signals
        rst_n = 1'b0;
        current_in = '0;
        
        // Print test header
        $display("\n=== LIF Neuron Testbench Started ===");
        $display("Threshold: %d", THRESHOLD);
        $display("Leak Factor: %d", LEAK_FACTOR);
        $display("Refractory Period: %d\n", REFRACTORY_PERIOD);
        
        // Reset sequence
        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        #(CLK_PERIOD);
        
        // Test Case 1: Subthreshold behavior
        $display("Test Case 1: Subthreshold Behavior");
        repeat(10) begin
            current_in = 8'h40;  // Increased from 0x20 to 0x40
            #(CLK_PERIOD);
            $display("Time=%0t: current=%d, potential=%d, spike=%b", 
                    $time, current_in, membrane_potential, spike_out);
        end
        
        // Test Case 2: Threshold crossing
        $display("\nTest Case 2: Threshold Crossing");
        repeat(20) begin
            current_in = 8'hFF;  // Increased from 0x70 to 0xFF for faster threshold crossing
            #(CLK_PERIOD);
            $display("Time=%0t: current=%d, potential=%d, spike=%b, refractory=%d", 
                    $time, current_in, membrane_potential, spike_out, refractory_counter);
        end
        
        // Test Case 3: Negative current
        $display("\nTest Case 3: Negative Current");
        repeat(10) begin
            current_in = -8'h40;
            #(CLK_PERIOD);
            $display("Time=%0t: current=%d, potential=%d, spike=%b", 
                    $time, current_in, membrane_potential, spike_out);
        end
        
        // Test Case 4: Alternating current
        $display("\nTest Case 4: Alternating Current");
        repeat(10) begin
            current_in = $signed($random) >>> 2; // Scale random value
            #(CLK_PERIOD);
            $display("Time=%0t: current=%d, potential=%d, spike=%b", 
                    $time, current_in, membrane_potential, spike_out);
        end
        
        // End simulation
        #(CLK_PERIOD * 5);
        $display("\n=== LIF Neuron Testbench Completed ===");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 1000);
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Check for potential overflow - only detect true overflow conditions
    always @(posedge clk) begin
        if (membrane_potential === {1'b1, {(POTENTIAL_WIDTH-1){1'b1}}} ||  // Maximum negative
            membrane_potential === {1'b0, {(POTENTIAL_WIDTH-1){1'b1}}}) begin  // Maximum positive
            $display("WARNING: Potential overflow detected at time %0t!", $time);
        end
    end

    // Detailed signal monitoring
    // always @(posedge clk) begin
    //     if (rst_n && $time > 0) begin  // Skip monitoring during reset
    //         $display("\nTime=%0t:", $time);
    //         $display("  Input current     = %0d", current_in);
    //         $display("  Membrane potential= %0d", membrane_potential);
    //         if (!dut.in_refractory) begin
    //             $display("  Next potential    = %0d", membrane_potential + 
    //                 {{(POTENTIAL_WIDTH-INPUT_WIDTH){current_in[INPUT_WIDTH-1]}}, current_in} - 
    //                 (membrane_potential >>> LEAK_FACTOR));
    //         end else begin
    //             $display("  In refractory period - counter: %0d", refractory_counter);
    //         end
    //         $display("  Spike            = %0b", spike_out);
    //     end
    // end

endmodule
