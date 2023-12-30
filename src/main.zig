const std = @import("std");

const block = @import("block.zig");

const Blockchain = block.Blockchain;
const Block = block.Block;
const Transaction = block.Transaction;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var blockchain = Blockchain{
        .blocks = std.ArrayList(Block).init(gpa.allocator()),
    };
    defer blockchain.blocks.deinit();

    var genesisBlock = Block{
        .previous_hash = undefined,
        .transactions = std.ArrayList(Transaction).init(gpa.allocator()),
        .hash = calculateGenesisHash(),
        .nonce = 0,
    };
    try blockchain.addBlock(genesisBlock);

    printBlockchain(&blockchain);
}

fn printBlockchain(blockchain: *Blockchain) void {
    std.debug.print("Blockchain:\n", .{});
    for (blockchain.blocks.items, 0..) |b, index| {
        std.debug.print("Block {}: \n", .{index});
        std.debug.print("    Previous Hash: {}\n", .{b.previous_hash});
        std.debug.print("    Hash: {}\n", .{b.hash});
        std.debug.print("    Nonce: {}\n", .{b.nonce});
    }
}

pub fn calculateGenesisHash() std.ArrayList(u8) {
    var s = std.ArrayList(u8).init(std.heap.page_allocator);
    defer s.deinit();

    // Add some unique data for the genesis block
    s.appendSlice("Genesis Block".*); // Example data
    s.appendSlice(u64ToBytes(0)); // Example nonce

    // Simple hash calculation (not cryptographically secure)
    var hash: std.ArrayList(u8) = undefined;
    var hashVal: u64 = 0;
    for (s.items) |b| {
        // A basic hash function, for example, a rolling hash
        hashVal = (hashVal * 31) ^ b;
    }

    // Convert the hash value to a byte array
    std.mem.writeIntLittle(u64, &hash, hashVal);
    return hash;
}

fn u64ToBytes(value: u64) []const u8 {
    var buffer: [8]u8 = undefined;
    std.mem.writeIntLittle(u64, &buffer, value);
    return buffer[0..];
}
