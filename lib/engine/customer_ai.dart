import 'dart:math' as math;

import '../data/balance.dart';
import 'entities.dart';
import 'stations.dart';

/// Customer behavioral state in the Dhaba ecosystem.
enum CustomerState {
  spawning, // Entering dhaba through front door, walking towards queue
  waitingInQueue, // Waiting in line in front of the serving counter
  beingServed, // Actively receiving food at the head of the queue
  walkingToTable, // Walking to assigned dining table to sit
  eating, // Sitting at dining table, eating/drinking
  leavingHappy, // Satisfied customer walking towards exit door
  leavingUnhappy, // Disappointed customer leaving due to unattended counter
  despawned, // Left the dhaba floor, removed from simulation
}

/// Represents an individual customer with personality, order, and AI state.
class CustomerEntity {
  final int id;
  final Vector2 position;
  Vector2 targetPosition;
  double speed;
  double radius;
  double angle; // Facing angle in radians

  CustomerState state;
  final ItemType desiredItem;
  final int desiredCount;
  int receivedCount;

  // Background patience timer (only counts down when at front of queue without cashier)
  final double patienceTime;
  double patienceTimer;

  // Visual variation (0: Shalwar Kameez Blue, 1: Green, 2: Maroon, 3: Saffron)
  final int variant;
  double walkCycle;
  bool isMoving;

  // Dine-in table dining state (M5)
  DiningTable? assignedTable;
  TableSeat? assignedSeat;
  double eatTimer;
  final double eatDuration;
  bool hasDinedIn;

  CustomerEntity({
    required this.id,
    required Vector2 startPosition,
    required this.targetPosition,
    this.speed = GameBalance.customerSpeed,
    this.radius = 18.0,
    this.desiredItem = ItemType.chai,
    this.desiredCount = 1,
    this.patienceTime = GameBalance.customerPatienceTime,
    this.eatDuration = GameBalance.customerEatDuration,
    this.variant = 0,
  }) : position = startPosition.copy(),
       angle = -math.pi / 2, // Facing North (towards counter)
       state = CustomerState.spawning,
       receivedCount = 0,
       patienceTimer = 0.0,
       walkCycle = 0.0,
       isMoving = false,
       eatTimer = 0.0,
       assignedTable = null,
       assignedSeat = null,
       hasDinedIn = false;

  bool get isOrderComplete => receivedCount >= desiredCount;
  bool get isLeaving =>
      state == CustomerState.leavingHappy ||
      state == CustomerState.leavingUnhappy;

  /// Progresses movement towards target position.
  void update(double dt) {
    if (dt <= 0.0) return;

    if (state == CustomerState.eating) {
      isMoving = false;
      walkCycle = 0.0;
      angle = assignedSeat?.facingAngle ?? -math.pi / 2;
      eatTimer += dt;
      return;
    }

    final dist = position.distanceTo(targetPosition);
    final step = speed * dt;
    if (dist <= step || dist <= 2.0) {
      position.x = targetPosition.x;
      position.y = targetPosition.y;
      isMoving = false;
      walkCycle = 0.0;

      // When standing in queue facing the counter, face North (-pi/2)
      if (state == CustomerState.waitingInQueue ||
          state == CustomerState.beingServed) {
        angle = -math.pi / 2;
      } else if (state == CustomerState.walkingToTable) {
        // Arrived at dining table seat! Transition to eating
        state = CustomerState.eating;
        eatTimer = 0.0;
        angle = assignedSeat?.facingAngle ?? -math.pi / 2;
        assignedSeat?.isSeated = true;
      }
    } else {
      isMoving = true;
      final dx = targetPosition.x - position.x;
      final dy = targetPosition.y - position.y;

      position.x += (dx / dist) * step;
      position.y += (dy / dist) * step;

      angle = math.atan2(dy, dx);
      walkCycle = (walkCycle + dt * 12.0) % (math.pi * 2);
    }
  }
}

/// Manages customer queue slot positions and line progression in front of counter.
class CustomerQueue {
  final List<CustomerEntity> customers = [];
  final Vector2 headPosition;
  final double spacing;
  final int maxCapacity;

  CustomerQueue({
    Vector2? headPosition,
    this.spacing = 46.0,
    this.maxCapacity = GameBalance.maxQueueCapacity,
  }) : headPosition = headPosition ?? Vector2(450.0, 782.0);

  bool get isFull => customers.length >= maxCapacity;
  bool get isEmpty => customers.isEmpty;
  int get count => customers.length;

  CustomerEntity? get head => customers.isNotEmpty ? customers.first : null;

  /// Computes world position for slot [index] in queue.
  Vector2 getSlotPosition(int index) {
    return Vector2(headPosition.x, headPosition.y + index * spacing);
  }

  /// Adds a customer to the back of the queue.
  bool enqueue(CustomerEntity customer) {
    if (isFull) return false;
    customers.add(customer);
    customer.targetPosition = getSlotPosition(customers.length - 1);
    return true;
  }

  /// Removes the served/departed customer from head of queue and advances everyone forward.
  CustomerEntity? dequeue() {
    if (customers.isEmpty) return null;
    final removed = customers.removeAt(0);
    updateQueuePositions();
    return removed;
  }

  /// Removes customer if present and advances queue.
  void removeCustomer(CustomerEntity customer) {
    if (customers.remove(customer)) {
      updateQueuePositions();
    }
  }

  /// Updates each customer's target position to match their new queue index.
  void updateQueuePositions() {
    for (int i = 0; i < customers.length; i++) {
      customers[i].targetPosition = getSlotPosition(i);
      // Reset patience timer if a new customer becomes head of queue
      if (i == 0 && customers[i].patienceTimer > 0.0) {
        customers[i].patienceTimer = 0.0;
      }
    }
  }
}

/// Orchestrates customer spawning, queue management, cashier service transactions,
/// dine-in eating, and despawning.
class CustomerSystem {
  final CustomerQueue queue;
  final List<CustomerEntity> activeCustomers;
  final Vector2 entrancePosition;
  List<DiningTable> diningTables;

  double spawnInterval;
  double spawnTimer;
  int nextCustomerId;

  // Event callbacks
  void Function(CustomerEntity, ItemType)? onCustomerServed;
  void Function(CustomerEntity)? onCustomerLeftUnhappy;
  void Function(CustomerEntity)? onCustomerCrowdedOut;
  void Function(CustomerEntity)? onCustomerSpawned;
  void Function(CustomerEntity, DiningTable)? onCustomerDinedIn;
  void Function(CustomerEntity, DiningTable)? onCustomerFinishedEating;

  CustomerSystem({
    CustomerQueue? queue,
    Vector2? entrancePosition,
    List<DiningTable>? tables,
    this.spawnInterval = GameBalance.customerSpawnInterval,
  }) : queue = queue ?? CustomerQueue(),
       entrancePosition = entrancePosition ?? Vector2(450.0, 1165.0),
       diningTables = tables ?? [],
       activeCustomers = [],
       spawnTimer = 0.0,
       nextCustomerId = 1;

  /// Spawns a new customer at the entrance and enqueues them.
  CustomerEntity? spawnCustomer({
    ItemType item = ItemType.chai,
    int count = 1,
  }) {
    if (queue.isFull) return null;

    final customer = CustomerEntity(
      id: nextCustomerId++,
      startPosition: entrancePosition.copy(),
      targetPosition: queue.getSlotPosition(queue.count),
      desiredItem: item,
      desiredCount: count,
      variant: (nextCustomerId) % 4,
    );

    activeCustomers.add(customer);
    queue.enqueue(customer);
    onCustomerSpawned?.call(customer);
    return customer;
  }

  /// Spawns a customer when the queue is full who observes the crowd and leaves unhappy.
  CustomerEntity? spawnCrowdedCustomer() {
    final customer = CustomerEntity(
      id: nextCustomerId++,
      startPosition: entrancePosition.copy(),
      targetPosition: Vector2(entrancePosition.x, entrancePosition.y - 45.0),
      desiredItem: ItemType.chai,
      desiredCount: 1,
      variant: (nextCustomerId) % 4,
    );
    activeCustomers.add(customer);
    onCustomerCrowdedOut?.call(customer);
    return customer;
  }

  /// Main simulation tick for Customer AI.
  void update(double dt, ServingCounter counter) {
    if (dt <= 0.0) return;

    // 1. Spawning
    spawnTimer += dt;
    if (!queue.isFull) {
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0.0;
        // Mostly 1 cup, occasionally 2 cups for variety
        final orderCount = (nextCustomerId % 4 == 0) ? 2 : 1;
        spawnCustomer(item: ItemType.chai, count: orderCount);
      }
    } else {
      // Queue is full: customers occasionally arrive, see the crowd, and turn away
      if (spawnTimer >= spawnInterval * 1.6) {
        spawnTimer = 0.0;
        spawnCrowdedCustomer();
      }
    }

    // 2. Update movement and dining for all active customers
    for (final customer in activeCustomers) {
      customer.update(dt);

      // Transition to waitingInQueue when reached destination slot, or leavingUnhappy if crowded out
      if (customer.state == CustomerState.spawning && !customer.isMoving) {
        if (queue.customers.contains(customer)) {
          customer.state = CustomerState.waitingInQueue;
        } else {
          customer.state = CustomerState.leavingUnhappy;
          customer.targetPosition = entrancePosition.copy();
          onCustomerLeftUnhappy?.call(customer);
        }
      }

      // Check dine-in eating duration completion
      if (customer.state == CustomerState.eating) {
        if (customer.eatTimer >= customer.eatDuration) {
          final table = customer.assignedTable;
          final seat = customer.assignedSeat;
          if (seat != null) {
            seat.isOccupied = false;
            seat.isSeated = false;
            seat.hasDirtyTray = true;
            seat.cashTip = GameBalance.dineInTip; // Leave Rs 25 tip at this seat!
          }
          if (table != null) {
            onCustomerFinishedEating?.call(customer, table);
          }
          customer.assignedSeat = null;
          customer.assignedTable = null;
          customer.hasDinedIn = true;
          customer.state = CustomerState.leavingHappy;
          customer.targetPosition = entrancePosition.copy();
        }
      }
    }

    // 3. Service transaction & patience check at head of queue
    final headCustomer = queue.head;
    if (headCustomer != null) {
      final slot0Pos = queue.getSlotPosition(0);
      final isAtFront = headCustomer.position.distanceTo(slot0Pos) < 18.0;

      if (isAtFront && !headCustomer.isLeaving) {
        headCustomer.state = CustomerState.waitingInQueue;

        bool wasServed = false;
        if (counter.isCashierPresent && counter.canServe()) {
          final served = counter.takeFoodItem(headCustomer.desiredItem);
          if (served != null) {
            wasServed = true;
            headCustomer.patienceTimer = 0.0; // Reset patience when served an item
            counter.triggerService();
            counter.addCashBundle(); // Cash bundle placed on counter's right cash tray!
            headCustomer.receivedCount++;
            headCustomer.state = CustomerState.beingServed;
            onCustomerServed?.call(headCustomer, served);

            if (headCustomer.isOrderComplete) {
              // Find first available seat across all unlocked dining tables (M5)
              TableSeat? targetSeat;
              DiningTable? targetTable;
              for (final table in diningTables) {
                if (table.isUnlocked) {
                  final freeSeat = table.firstAvailableSeat;
                  if (freeSeat != null) {
                    targetSeat = freeSeat;
                    targetTable = table;
                    break;
                  }
                }
              }

              if (targetSeat != null && targetTable != null) {
                // Customer claims specific seat and walks to sit down
                targetSeat.isOccupied = true;
                targetSeat.isSeated = false;
                headCustomer.assignedTable = targetTable;
                headCustomer.assignedSeat = targetSeat;
                headCustomer.state = CustomerState.walkingToTable;
                headCustomer.targetPosition = targetSeat.position.copy();
                queue.dequeue();
                onCustomerDinedIn?.call(headCustomer, targetTable);
              } else {
                // Takeaway to go!
                headCustomer.state = CustomerState.leavingHappy;
                headCustomer.targetPosition = entrancePosition.copy();
                queue.dequeue();
              }
            }
          }
        }

        // If customer was NOT served on this tick, patience timer progresses
        if (!wasServed && !headCustomer.isLeaving) {
          headCustomer.patienceTimer += dt;
          if (headCustomer.patienceTimer >= headCustomer.patienceTime) {
            // Customer leaves disappointed
            headCustomer.state = CustomerState.leavingUnhappy;
            headCustomer.targetPosition = entrancePosition.copy();
            queue.dequeue();
            onCustomerLeftUnhappy?.call(headCustomer);
          }
        }
      }
    }

    // 4. Despawn customers when they reach the entrance door
    final toRemove = <CustomerEntity>[];
    for (final customer in activeCustomers) {
      if (customer.isLeaving) {
        final distToExit = customer.position.distanceTo(entrancePosition);
        if (distToExit < 16.0) {
          customer.state = CustomerState.despawned;
          toRemove.add(customer);
        }
      }
    }

    activeCustomers.removeWhere((c) => toRemove.contains(c));
  }
}
