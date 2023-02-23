pragma circom 2.0.4;

// Check that in0 and in1 are not equal
template NonEqual() {
    signal input in0;
    signal input in1;
    // Check that in0 - in1 is not 0
    signal inverse;
    inverse <-- 1 / (in0 - in1);
    inverse * (in0 - in1) === 1;
}

// Taken from https://github.com/iden3/circomlib/blob/master/circuits/comparators.circom
template IsZero() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}

// Taken from https://github.com/iden3/circomlib/blob/master/circuits/comparators.circom
template IsEqual() {
    signal input in[2];
    signal output out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    isz.out ==> out;
}

template CheckNodePair() {
    signal input color1;
    signal input color2;
    signal input areNeighbors;

    component isEqual = IsEqual();
    isEqual.in[0] <== color1;
    isEqual.in[1] <== color2;

    isEqual.out * areNeighbors === 0;
}

// Enfore 0 <= in < 4
template Bits2() {
    signal input in;
    signal bits[2];
    var bitsum = 0;
    for (var i = 0; i < 2; i++) {
        bits[i] <-- (in >> i) & 1;
        bits[i] * (bits[i] - 1) === 0;
        bitsum = bitsum + 2 ** i * bits[i];
    }
    bitsum === in;
}

template OnetoThree() {
    signal input in;
    component lowerBound = Bits2();
    component upperBound = Bits2();
    // lowerBound checks 0 <= (in - 1) < 4 ==> 1 <= in < 5
    // upperBound checks 0 <= in < 4
    // combining those constraints we get 1 <= in < 4 ==> 1 <= in <= 3, as desired
    lowerBound.in <== in - 1; 
    upperBound.in <== in;
}

template ThreeColoring(n) {
    signal input edges[n][n]; 
    signal input colors[n];

    // Ensure all colors are in set {1, 2, 3}
    component inRange[n];
    for (var node = 0; node < n; node++) {
        inRange[node] = OnetoThree();
        inRange[node].in <== colors[node];
    }

    // Ensure the colors of a node's neighbors don't match the node's color
    component checkNeighbor[n][n];
    for (var node = 0; node < n; node++) {
        for (var neighbor = 0; neighbor < n; neighbor++) {
            checkNeighbor[node][neighbor] = CheckNodePair();
            checkNeighbor[node][neighbor].color1 <== colors[node];
            checkNeighbor[node][neighbor].color2 <== colors[neighbor];
            checkNeighbor[node][neighbor].areNeighbors <== edges[node][neighbor];
        }
    }
}

component main {public[edges]} = ThreeColoring(10);
