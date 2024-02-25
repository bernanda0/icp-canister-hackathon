import tp "../types";
import ut "../utils";
import Map "mo:map/Map";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

actor DB {
    stable var baggage_data = Map.new<tp.BaggageMapKey, tp.BaggageData>();
    // stable var user_data = Map.new<>(tp.);

    public func addBaggageData(user_id : Text, value : tp.BaggageData) : async tp.Res<tp.BaggageData, Text> {
        // userId used for authentication and verification
        var key : tp.BaggageMapKey = { baggage_id = value.baggage_id };
        Map.set(baggage_data, ut.khash, key, value);
        if (Map.has(baggage_data, ut.khash, key)) {
            return #ok(value);
        };
        return #err("Failed to add baggage data");
    };

    public shared func updateBaggageEvent(key : tp.BaggageMapKey, baggagePayload : tp.UpdatePayload) : async Bool {
        var baggageData = Map.get(baggage_data, ut.khash, key);
        switch (baggageData) {
            case (?myDt) {
                var existing_event = Buffer.fromArray<tp.BaggageEvent>(myDt.events);
                existing_event.add(baggagePayload.b_event);

                var newBaggageData : tp.BaggageData = {
                    baggage_id = myDt.baggage_id;
                    owner = myDt.owner;
                    departure = myDt.departure;
                    destination = myDt.destination;
                    airline = myDt.airline;
                    weight = myDt.weight;
                    dimension = myDt.dimension;
                    category = myDt.category;
                    is_fragile = myDt.is_fragile;
                    events = Buffer.toArray(existing_event);
                };

                Map.set(baggage_data, ut.khash, key, newBaggageData);
                return true;
            };
            case null {
                return false;
            };
        };

    };

    public query func getBaggageData(userId: Text, key : tp.BaggageMapKey) : async tp.Res<tp.BaggageData, Text> {
        // check if the userId is the owner of the baggage
        var baggageData = Map.get(baggage_data, ut.khash, key);
        switch (baggageData) {
            case (?myDt) {
                return #ok(myDt);
            };
            case null {
                return #err("Failed to get baggage data.");
            }
        };
    };

    public query func bagIdExists(bagId : Text) : async Bool {
        return Map.has(baggage_data, ut.khash, { baggage_id = bagId });
    };

    // public func deleteBaggageData(key : tp.BaggageMapKey) : async tp.Res<tp.BaggageData, Text> {
    //     var baggageData = Map.get(baggage_data, ut.khash, key);
    //     switch (baggageData) {
    //         case (?myDt) {
    //             Map.delete(baggage_data, ut.khash, key);
    //             return #ok(myDt);
    //         };
    //         case null {
    //             return #err("Failed deleting, no data found");
    //         }
    //     };
    // };

    // resetting baggage data
    public func resetBaggageData() : async Text {
        baggage_data := Map.new<tp.BaggageMapKey, tp.BaggageData>();
        return debug_show(baggage_data);
    }
};
