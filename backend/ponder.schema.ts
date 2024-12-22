import { onchainTable } from "@ponder/core";

export const EscrowCreatedEvents = onchainTable("EscrowCreatedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  depositor: t.text(),
  receiver: t.text(),
  token: t.text(),
  amount: t.text(),
  expiryDate: t.text(),
}));

export const EscrowAcceptedEvents = onchainTable("EscrowAcceptedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  receiver: t.text()
}));

export const ReleaseRequestedEvents = onchainTable("ReleaseRequestedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),
}));

export const EscrowCompletedEvents = onchainTable("EscrowCompletedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  receiver: t.text(),
  amount: t.text()
}));

export const EscrowRefundedEvents = onchainTable("EscrowRefundedEvents", (t) => ({
  id: t.text().primaryKey(),
  escrowId: t.integer(),  
  depositor: t.text()
}));

export const FeesWithdrawnEvents = onchainTable("FeesWithdrawnEvents", (t) => ({
  id: t.text().primaryKey(),
  token: t.text(),
  amount: t.text()
}));