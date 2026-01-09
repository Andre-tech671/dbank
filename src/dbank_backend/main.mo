import Debug "mo:base/Debug";

persistent actor Dbank {
  var currentValue : Nat = 300;
    currentValue := 100;

    let id = 2345678910;
    // Print the current value using debug_show
    Debug.print(debug_show(id));

//making the funcion to top up the value and its a public function
//Allows users to add funds to their account
    public func topUp(amount : Nat) {
      currentValue += amount;
      Debug.print(debug_show(currentValue));
    };

//Allows users to wothdraw funds from their account
    public func withdraw(amount : Nat) {
      if (amount <= currentValue) {
        currentValue -= amount;
        Debug.print(debug_show(currentValue));
      } else {
        Debug.print("Insufficient funds");
      }
    };

    //decrease the value by which the user wants to withdraw
    

    //topUp();
};
  