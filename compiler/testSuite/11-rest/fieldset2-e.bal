public type R1 record {|
    int x;
    int...;
|};

public type R2 record {|
    int y;
    int...;
|};
public function foo(R1|R2 r) {
    r.x = 1; // @error
}