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

// Check that all elements in `in` are unique
template Distinct(n) {
    signal input in[n];
    // We check this by setting a constraint that
    // no pair of elements in have the same values
    component nonEqual[n][n];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < i; j++) {
            nonEqual[i][j] = NonEqual();
            nonEqual[i][j].in0 <== in[i];
            nonEqual[i][j].in1 <== in[j];
        }
    }
}

template DistinctSubsquare(sqrtN, rowOffset, colOffset) {
    var n = sqrtN * sqrtN;
    signal input solution[n][n];
    component distinct = Distinct(n);
    var i = 0;
    for (var row = sqrtN * rowOffset; row < sqrtN * rowOffset + sqrtN; row++) {
        for (var col = sqrtN * colOffset; col < sqrtN * colOffset + sqrtN; col++) {
            distinct.in[i] <== solution[row][col];
            i = i + 1;
        }
    }
}

// Enforce 0 <= in < 16
template Bits4() {
    signal input in;
    signal bits[4];
    var bitsum = 0;
    for (var i = 0; i < 4; i++) {
        bits[i] <-- (in >> i) & 1;
        bits[i] * (bits[i] - 1) === 0;
        bitsum = bitsum + 2 ** i * bits[i];
    }
    bitsum === in;
}

// Enforce 1 <= in <= 9
template OneToNine() {
    signal input in;
    component lowerBound = Bits4();
    component upperBound = Bits4();
    lowerBound.in <== in - 1;
    upperBound.in <== in + 6;
}

template Sudoku(n) {
    // solution is a 2D array; indices are (row_i, col_i)
    signal input solution[n][n];
    // puzzle is the same, but a zero indicates a blank
    signal input puzzle[n][n];

    component inRange[n][n]; // Constraint that each element in the solution is between 1 and 9
    component rowIsDistinct[n]; // Constraint that each row in the solution has no duplicates

    for (var row = 0; row < n; row++) {

        // Row duplicate check
        rowIsDistinct[row] = Distinct(n);
        rowIsDistinct[row].in <== solution[row];

        for (var col = 0; col < n; col++) {
            // In range check
            inRange[row][col] = OneToNine();
            inRange[row][col].in <== solution[row][col];

            // Constraint that the solution agrees with the puzzle
            // If the puzzle cell is 0 then the first term in the product will be 0 and the constraint will be satisfied
            // If the puzzle cell is not 0 then the second term in the product will be 0 if and only if the puzzle cell and solution cell have the same value, and the constraint will be satisfied
            puzzle[row][col] * (puzzle[row][col] - solution[row][col]) === 0;
        }
    }

    component colIsDistinct[n]; // Constraint that each column in the solution has no duplicates
    for (var col = 0; col < n; col++) {
        colIsDistinct[col] = Distinct(n);
        for (var row = 0; row < n; row++) {
            // Column duplicate check
            colIsDistinct[col].in[row] <== solution[row][col];
        }
    }

    // Verify the subsquares
    var sqrtN = 0;
    while (sqrtN * sqrtN < n) {
        sqrtN = sqrtN + 1;
    }
    component distinctSubsquares[n];
    var subsquareIndex = 0;
    for (var rowOffset = 0; rowOffset < sqrtN; rowOffset++) {
        for (var colOffset = 0; colOffset < sqrtN; colOffset++) {
            distinctSubsquares[subsquareIndex] = DistinctSubsquare(sqrtN, rowOffset, colOffset);
            distinctSubsquares[subsquareIndex].solution <== solution;
            subsquareIndex = subsquareIndex + 1;
        }
    }
}

component main {public[puzzle]} = Sudoku(9);