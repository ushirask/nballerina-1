import ballerina/io;
public function main() {
    io:println(-9.999999999999999999999999999999999E6144d + -0.000000000000000000000000000000001E6144d); // @error
}
