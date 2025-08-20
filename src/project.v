`default_nettype none

module tt_um_tdctest_container (
    // Include power ports for the Gate Level test:
    `ifdef GL_TEST
        input wire VPWR,
        input wire VGND,
    `endif
    input  wire [7:0] ui_in,       // Dedicated inputs
    output wire [7:0] uo_out,      // Dedicated outputs
    input  wire [7:0] uio_in,      // IOs: Input path
    output wire [7:0] uio_out,     // IOs: Output path
    output wire [7:0] uio_oe,      // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,         // always 1 when the design is powered, so you can ignore it
    input  wire       clk,         // clock
    input  wire       rst_n        // reset_n - low to reset
);

    // Internal select signal
    wire [1:0] sel = uio_in[1:0];

    // Output signals from each module
    // Outputs from the sensor module
    wire [7:0] sensor_out;
    wire sensor_delayed_clk_o;
    wire sensor_start_o;
    wire tdc_mux_sel_i;
    wire [7:0] tdc_out;
    wire [7:0] ro_out;
    wire [7:0] ro2_out;

    // System input selection signal for the TDC
    assign tdc_mux_sel_i = ui_in[0];
    // Assign specific bits of sensor_out to named signals
    assign sensor_delayed_clk_o = sensor_out[1];
    assign sensor_start_o       = sensor_out[0];

    // Top-level output selection based on the `sel` signal
    assign uo_out  = (sel == 2'b00) ? sensor_out :
                     (sel == 2'b01) ? tdc_out :
                     (sel == 2'b10) ? ro_out :
                                      ro2_out;

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, uio_in[7:2], 1'b0};

    // Instantiate the sensor module
    tt_um_roy1707018_sensor proj1 (
        .rst_n(rst_n),
        .clk(clk),
        .ui_in(8'h00),
        .uo_out(sensor_out)
    );

    // Instantiate the TDC module, using outputs from the sensor as inputs
    tt_um_roy1707018_tdc proj2 (
        .rst_n(rst_n),
        .clk(sensor_delayed_clk_o),                  // Use sensor's delayed clock output as TDC clock
        .ui_in({6'b0, tdc_mux_sel_i, sensor_start_o}),  // Input from sensor and system selection
        .uo_out(tdc_out)
    );

    // Instantiate the first Ring Oscillator module
    tt_um_roy1707018_ro proj3 (
        .rst_n(rst_n),
        .clk(clk),
        .ui_in({6'b0, ui_in[2:1]}),     // Relevant inputs from ui_in
        .uo_out(ro_out)
    );

    // Instantiate the second Ring Oscillator module
    tt_um_roy1707018_ro2 proj4 (
        .rst_n(rst_n),
        .clk(clk),
        .ui_in({6'b0, ui_in[4:3]}),     // Relevant inputs from ui_in
        .uo_out(ro2_out)
    );

endmodule

