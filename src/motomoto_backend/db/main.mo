import tp "../types";
import ut "../utils";
import Map "mo:map/Map";
import Debug "mo:base/Debug";

actor {
    stable var baggage_data = Map.new<tp.BaggageMapKey, tp.BaggageData>();

    public func addBaggageData(key : tp.BaggageMapKey, value : tp.BaggageData) {
        Map.set(baggage_data, ut.khash, key, value);
    };

    public func updateBaggageEvent(key : tp.BaggageMapKey, baggageStatus : tp.BaggageStatus, baggageEvent : tp.BaggageEvent) {
        var baggageData = Map.get(baggage_data, ut.khash, key);
        switch (baggageData) {
            case (?myDt) {
                var newBaggageData : tp.BaggageData = {
                    baggage_id = myDt.baggage_id;
                    owner = myDt.owner;
                    weight = myDt.weight;
                    destination = myDt.destination;
                    status = baggageStatus;
                    event = baggageEvent;
                };
                Map.set(baggage_data, ut.khash, key, newBaggageData);
            };
            case null {
                Debug.print(debug_show ("No data found for key: ", key));
            };
        };

    };

    // get function
};
