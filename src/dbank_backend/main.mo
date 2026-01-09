import Debug "mo:base/Debug";

persistent actor Dbank {
  var currentValue : Nat = 300;
    currentValue := 100;

    let id = 2345678910;
    // Print the current value using debug_show
    Debug.print(debug_show(id));
};
