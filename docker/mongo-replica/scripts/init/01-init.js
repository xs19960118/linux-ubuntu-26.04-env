rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-1:27017" },
    { _id: 1, host: "mongo-2:27017" },
    { _id: 2, host: "mongo-3:27017" }
  ]
});

db = db.getSiblingDB("app_db");
db.createUser({ user: "xs", pwd: "xsailxma", roles: [{ role: "readWrite", db: "app_db" }, { role: "dbAdmin", db: "app_db" }] });
