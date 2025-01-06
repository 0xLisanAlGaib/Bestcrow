import { ponder } from "ponder:registry";
import { EscrowCreatedEvents, EscrowAcceptedEvents, EscrowCompletedEvents, ReleaseRequestedEvents, EscrowRefundedEvents, FeesWithdrawnEvents, EscrowRejectedEvents } from "../ponder.schema";
import { formatUnits } from 'viem'



ponder.on("Bestcrow:EscrowCreated", async ({ event, context }) => {
    await context.db.insert(EscrowCreatedEvents)
      .values({
        id: event.transaction.hash,
        escrowId: Number(event.args.escrowId),
        depositor: event.args.depositor,
        receiver: event.args.receiver,         
        token: event.args.token,
        amount: formatUnits(event.args.amount, 0),
        expiryDate: BigInt(event.args.expiryDate),
        createdAt: BigInt(event.block.timestamp),
        title: event.args.title,
        description: event.args.description
      })
      .onConflictDoNothing();
});


ponder.on("Bestcrow:EscrowAccepted", async ({ event, context }) => {
    await context.db.insert(EscrowAcceptedEvents)
    .values({
      id: event.transaction.hash,
      escrowId: Number(event.args.escrowId),
      receiver: event.args.receiver,
    })
    .onConflictDoNothing();
});

ponder.on("Bestcrow:EscrowRejected", async ({ event, context }) => {
  await context.db.insert(EscrowRejectedEvents)
    .values({
      id: event.transaction.hash,
      escrowId: Number(event.args.escrowId),
      receiver: event.args.receiver
    })
    .onConflictDoNothing();
});

ponder.on("Bestcrow:ReleaseRequested", async ({ event, context }) => {
  await context.db.insert(ReleaseRequestedEvents)
    .values(
      { id: event.transaction.hash,
        escrowId: Number(event.args.escrowId),
      },
    )
    .onConflictDoNothing();
});

ponder.on("Bestcrow:EscrowCompleted", async ({ event, context }) => {
  await context.db.insert(EscrowCompletedEvents)
    .values(
      { id: event.transaction.hash,
        escrowId: Number(event.args.escrowId),
        receiver: event.args.receiver,
        amount: formatUnits(event.args.amount, 0),
      },
    )
    .onConflictDoNothing();
    
});

ponder.on("Bestcrow:EscrowRefunded", async ({ event, context }) => {
  await context.db.insert(EscrowRefundedEvents)
    .values(
      { id: event.transaction.hash,
        escrowId: Number(event.args.escrowId),
        depositor: event.args.depositor
      },
    )
    .onConflictDoNothing();
});

ponder.on("Bestcrow:FeesWithdrawn", async ({ event, context }) => {
  await context.db.insert(FeesWithdrawnEvents)
    .values(
      { id: event.transaction.hash,
        token: event.args.token,
        amount: formatUnits(event.args.amount, 0)
      },
    )
    .onConflictDoNothing();
});