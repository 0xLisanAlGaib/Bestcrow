import { onchainTable } from "@ponder/core";

export const EscrowCreatedEvents = onchainTable("EscrowCreatedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  depositor: t.hex(),
  receiver: t.hex(),
  token: t.hex(),
  amount: t.text(),
  expiryDate: t.bigint(),
  createdAt: t.bigint(),
  title: t.text(),
  description: t.text(),
}));

export const EscrowAcceptedEvents = onchainTable("EscrowAcceptedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  receiver: t.hex()
}));

export const EscrowRejectedEvents = onchainTable("EscrowRejectedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),
  receiver: t.hex()
}));

export const ReleaseRequestedEvents = onchainTable("ReleaseRequestedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),
}));

export const EscrowCompletedEvents = onchainTable("EscrowCompletedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  receiver: t.hex(),
  amount: t.text()
}));

export const EscrowRefundedEvents = onchainTable("EscrowRefundedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  depositor: t.hex()
}));

export const FeesWithdrawnEvents = onchainTable("FeesWithdrawnEvents", (t) => ({
  id: t.text().primaryKey(),
  token: t.hex(),
  amount: t.text()
}));
