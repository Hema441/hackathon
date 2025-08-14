module Vehicle_Co::AVCNVehicle {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::string::String;

    /// Vehicle registration and tracking data
    struct Vehicle has store, key {
        vin: String,                    // Vehicle Identification Number
        owner_address: address,         // Owner's wallet address
        registration_expiry: u64,       // Registration expiry timestamp
        insurance_expiry: u64,          // Insurance expiry timestamp
        pollution_expiry: u64,          // Pollution certificate expiry
        is_active: bool,                // Vehicle active status
        biometric_hash: String,         // Owner's biometric data hash
        total_fees_paid: u64,          // Total renewal fees paid
    }

    /// Treasury to store collected fees
    struct Treasury has key {
        balance: u64,
    }

    /// Initialize treasury (call this once after deployment)
    public fun initialize_treasury(admin: &signer) {
        let treasury = Treasury {
            balance: 0,
        };
        move_to(admin, treasury);
    }

    /// Register a new vehicle in the system
    public fun register_vehicle(
        owner: &signer,
        vin: String,
        registration_expiry: u64,
        insurance_expiry: u64,
        pollution_expiry: u64,
        biometric_hash: String
    ) {
        let owner_address = signer::address_of(owner);
        
        let vehicle = Vehicle {
            vin,
            owner_address,
            registration_expiry,
            insurance_expiry,
            pollution_expiry,
            is_active: true,
            biometric_hash,
            total_fees_paid: 0,
        };
        
        move_to(owner, vehicle);
    }

    /// Renew vehicle documents and process payment
    public fun renew_documents(
        owner: &signer,
        treasury_address: address,
        renewal_fee: u64,
        new_registration_expiry: u64,
        new_insurance_expiry: u64,
        new_pollution_expiry: u64
    ) acquires Vehicle, Treasury {
        let owner_address = signer::address_of(owner);
        let vehicle = borrow_global_mut<Vehicle>(owner_address);
        
        // Process payment - withdraw from owner and deposit to treasury
        let payment = coin::withdraw<AptosCoin>(owner, renewal_fee);
        coin::deposit<AptosCoin>(treasury_address, payment);
        
        // Update treasury record
        let treasury = borrow_global_mut<Treasury>(treasury_address);
        treasury.balance = treasury.balance + renewal_fee;
        
        // Update expiry dates
        vehicle.registration_expiry = new_registration_expiry;
        vehicle.insurance_expiry = new_insurance_expiry;
        vehicle.pollution_expiry = new_pollution_expiry;
        vehicle.total_fees_paid = vehicle.total_fees_paid + renewal_fee;
        vehicle.is_active = true;
    }

    /// View function to get vehicle details
    #[view]
    public fun get_vehicle_info(owner_address: address): (String, u64, u64, u64, bool, u64) acquires Vehicle {
        let vehicle = borrow_global<Vehicle>(owner_address);
        (
            vehicle.vin,
            vehicle.registration_expiry,
            vehicle.insurance_expiry,
            vehicle.pollution_expiry,
            vehicle.is_active,
            vehicle.total_fees_paid
        )
    }
}