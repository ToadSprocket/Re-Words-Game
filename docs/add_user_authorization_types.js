// MongoDB Migration Script: Add user_authorization_types Collection
// Purpose: Create the user_authorization_types lookup table
// Date: 2026-02-27
// Run with: mongosh rewordgame_v2 < add_user_authorization_types.js

// Switch to the database (adjust name if needed)
use rewordgame_v2;

print("Creating user_authorization_types collection...");

// Insert the authorization type records
db.user_authorization_types.insertMany([
  {
    userAuthorizationTypeId: 1,
    userAuthorizationTypeDescription: "Apple",
    isActive: true,
    createdAtUtc: new Date(),
    updatedAtUtc: new Date()
  },
  {
    userAuthorizationTypeId: 2,
    userAuthorizationTypeDescription: "Google",
    isActive: true,
    createdAtUtc: new Date(),
    updatedAtUtc: new Date()
  },
  {
    userAuthorizationTypeId: 3,
    userAuthorizationTypeDescription: "Email/Password",
    isActive: true,
    createdAtUtc: new Date(),
    updatedAtUtc: new Date()
  },
  {
    userAuthorizationTypeId: 4,
    userAuthorizationTypeDescription: "Anonymous",
    isActive: true,
    createdAtUtc: new Date(),
    updatedAtUtc: new Date()
  }
]);

print("✅ Inserted 4 user authorization types");

// Create unique index on userAuthorizationTypeId
db.user_authorization_types.createIndex(
  { userAuthorizationTypeId: 1 },
  { unique: true, name: "idx_user_authorization_type_id" }
);

print("✅ Created unique index on userAuthorizationTypeId");

// Create index on userAuthorizationTypeId for user_identity_links (if collection exists)
if (db.user_identity_links.countDocuments() > 0) {
  print("Creating index on user_identity_links.userAuthorizationTypeId...");
  db.user_identity_links.createIndex(
    { userAuthorizationTypeId: 1 },
    { name: "idx_user_identity_links_auth_type" }
  );
  print("✅ Created index on user_identity_links");
} else {
  print("ℹ️  user_identity_links collection doesn't exist yet, skipping index creation");
}

// Verify the data
print("\n📋 Verification:");
print("Total authorization types:", db.user_authorization_types.countDocuments());
print("\nAuthorization Types:");
db.user_authorization_types.find().forEach(function(doc) {
  print("  " + doc.userAuthorizationTypeId + ": " + doc.userAuthorizationTypeDescription);
});

print("\n✅ Migration complete!");
