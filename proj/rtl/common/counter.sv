module counter #(
    parameter WIDTH = 8,
    parameter COUNT_UP = 0,
    parameter CHECK_FOR_DONE = 1
) (
    input wire clk,
    input wire reset,
    input wire counter_tick,
    output wire done,
    output logic [WIDTH-1:0] count
);

generate;
    if (COUNT_UP == 0) begin
        always_ff @(posedge clk) begin
            if (reset) begin
                count <= '1;
            end else if (counter_tick) begin
                count <= count - 'd1;
            end
        end

        if (CHECK_FOR_DONE) assign done = ~(|count);
        else                assign done = 'x;

    end else begin
        always_ff @(posedge clk) begin
            if (reset) begin
                count <= '0;
            end else if (counter_tick) begin
                count <= count + 'd1;
            end
        end

        if (CHECK_FOR_DONE) assign done = &count;
        else                assign done = 'x;

    end
endgenerate

endmodule