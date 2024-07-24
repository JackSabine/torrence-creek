module counter #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire reset,
    input wire count_down,
    output wire done,
    output logic [WIDTH-1:0] count
);

always_ff @(posedge clk) begin
    if (reset) begin
        count <= '1;
    end else if (count_down) begin
        count <= count - 'd1;
    end
end

assign done = (count == '0);

endmodule