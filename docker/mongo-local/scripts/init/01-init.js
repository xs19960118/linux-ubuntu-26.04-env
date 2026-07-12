db = db.getSiblingDB("app_db");

db.createUser({
  user: "xs",
  pwd: "xsailxma",
  roles: [
    { role: "readWrite", db: "app_db" },
    { role: "dbAdmin", db: "app_db" }
  ]
});

db.createCollection("init_marker");
