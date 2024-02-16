use ic_cdk::storage;
use ic_cdk_macros::{storage};
use candid::{CandidType, Principal};

#[derive(CandidType)]
struct Note {
    id: Principal,
    content: String,
}

#[ic_cdk::query]
fn get_notes() -> Vec<Note> {
    // Retrieve notes from the database canister
    let notes: Vec<Note> = storage::stable_save(<Vec<Note>>("notes").unwrap_or_default());
    notes
}

#[ic_cdk::update]
fn add_note(content: String) {
    let id = ic_cdk::api::id();

    // Create a new note
    let note = Note { id, content };

    // Retrieve existing notes or initialize an empty vector
    let mut notes: Vec<Note> = storage::get::<Vec<Note>>("notes").unwrap_or_default();

    // Add the new note to the vector
    notes.push(note.clone());

    // Store the updated notes vector back to the database canister
    storage::set("notes", notes);
}


#[ic_cdk::query]
fn greet(name: String) -> String {
    format!("Hello, {}!", name)
}
