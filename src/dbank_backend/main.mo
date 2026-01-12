import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat "mo:base/Nat";


persistent actor Dbank {

  var currentValue : Float = 300.0;
  currentValue := 300.0;
  Debug.print("Initial value: " # debug_show(currentValue));

  var startTime = Time.now();
  Debug.print("Start time: " # debug_show(startTime));

  public func topUp(amount : Float) {
    currentValue += amount;
    Debug.print(debug_show(currentValue));
  };

  public func withdraw(amount : Float) {
    let tempValue : Float = currentValue - amount;
    if (tempValue >= 0.0) {
      currentValue -= amount;
      Debug.print(debug_show(currentValue));
    } else {
      Debug.print("Insufficient funds");
    }
  };

  public query func checkBalance(): async Float {
    return currentValue;
  };

  public func compoundDaily() {
    let currentTime = Time.now();
    let timeElapsedNS = currentTime - startTime;
    let timeElapsedDays = timeElapsedNS / (86_400 * 1_000_000_000); // seconds in a day

    let timeElapsedFloat = Float.fromInt(timeElapsedDays);
    currentValue := currentValue * (1.01 ** timeElapsedFloat);

    startTime := currentTime;
    Debug.print("New value after daily compounding: " # debug_show(currentValue));
  };
};
