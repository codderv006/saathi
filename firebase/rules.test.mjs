// Firestore rules tests against the local emulator. Run: npm test (in firebase/).
import { after, before, beforeEach, test } from "node:test";
import { readFileSync } from "node:fs";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, setDoc } from "firebase/firestore";

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-saathi",
    firestore: { rules: readFileSync("firestore.rules", "utf8"), host: "127.0.0.1", port: 8085 },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const session = (uid, overrides = {}) => ({
  id: "s1",
  installationId: "i1",
  userId: uid,
  workflowId: "ride_ola_v1",
  currentStepId: "open_app",
  status: "active",
  language: "mr",
  outcome: null,
  history: [],
  revision: 1,
  createdAt: "2026-10-21T00:00:00.000Z",
  updatedAt: "2026-10-21T00:00:00.000Z",
  ownerUid: uid,
  ...overrides,
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const seed = (path, data) =>
  env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), data));

test("owner can create, read and advance their session", async () => {
  const db = as("alice");
  await assertSucceeds(setDoc(doc(db, "sessions/s1"), session("alice")));
  await assertSucceeds(getDoc(doc(db, "sessions/s1")));
  await assertSucceeds(
    setDoc(doc(db, "sessions/s1"), session("alice", { revision: 2, currentStepId: "find_locations" })),
  );
});

test("other users cannot read, write or delete someone else's session", async () => {
  await seed("sessions/s1", session("alice"));
  const bob = as("bob");
  await assertFails(getDoc(doc(bob, "sessions/s1")));
  await assertFails(setDoc(doc(bob, "sessions/s1"), session("bob", { revision: 5 })));
  await assertFails(deleteDoc(doc(bob, "sessions/s1")));
});

test("signed-out access is denied", async () => {
  await seed("sessions/s1", session("alice"));
  const anon = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon, "sessions/s1")));
  await assertFails(setDoc(doc(anon, "sessions/s2"), session("alice", { id: "s2" })));
});

test("cannot create a session owned by someone else", async () => {
  await assertFails(setDoc(doc(as("bob"), "sessions/s1"), session("alice")));
});

test("stale or duplicate revision is rejected", async () => {
  await seed("sessions/s1", session("alice", { revision: 3 }));
  const db = as("alice");
  await assertFails(setDoc(doc(db, "sessions/s1"), session("alice", { revision: 3 })));
  await assertFails(setDoc(doc(db, "sessions/s1"), session("alice", { revision: 2 })));
  await assertSucceeds(setDoc(doc(db, "sessions/s1"), session("alice", { revision: 4 })));
});

test("completed or ended sessions cannot be reopened", async () => {
  for (const status of ["completed", "ended"]) {
    await seed("sessions/s1", session("alice", { status, revision: 9 }));
    await assertFails(
      setDoc(doc(as("alice"), "sessions/s1"), session("alice", { status: "active", revision: 10 })),
    );
  }
});

test("unexpected fields and values are rejected", async () => {
  const db = as("alice");
  await assertFails(setDoc(doc(db, "sessions/s1"), { ...session("alice"), otp: "123456" }));
  await assertFails(setDoc(doc(db, "sessions/s1"), session("alice", { language: "fr" })));
  await assertFails(setDoc(doc(db, "sessions/s1"), session("alice", { id: "other" })));
  await assertFails(setDoc(doc(db, "sessions/s1"), session("alice", { status: "hacked" })));
});

test("workflow cannot be swapped on an existing session", async () => {
  await seed("sessions/s1", session("alice"));
  await assertFails(
    setDoc(doc(as("alice"), "sessions/s1"), session("alice", { workflowId: "ride_uber_v1", revision: 2 })),
  );
});

test("users/{uid} pointer is private to its owner", async () => {
  const ok = { activeSessionId: "s1", installationId: "i1", language: "en", updatedAt: "x" };
  await assertSucceeds(setDoc(doc(as("alice"), "users/alice"), ok));
  await assertFails(getDoc(doc(as("bob"), "users/alice")));
  await assertFails(setDoc(doc(as("bob"), "users/alice"), ok));
  await assertFails(setDoc(doc(as("alice"), "users/alice"), { ...ok, phone: "999" }));
});

test("everything else is closed", async () => {
  await assertFails(setDoc(doc(as("alice"), "anything/x"), { a: 1 }));
});
