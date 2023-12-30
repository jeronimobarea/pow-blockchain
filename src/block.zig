const std = @import("std");

const Sha256 = std.crypto.hash.sha2.Sha256;

const NUM_LEADING_ZEROS_REQUIRED = 4;

pub const BlockchainError = error{
    InvalidBlock,
    InvalidProofOfWork,
};

pub const Blockchain = struct {
    blocks: std.ArrayList(Block),

    pub fn addBlock(self: *Blockchain, block: Block) !void {
        if (self.blocks.items.len == 0) {
            try self.blocks.append(block);
        } else {
            try self.validateBlock(block);
            try self.blocks.append(block);
        }
    }

    fn validateBlock(self: *Blockchain, block: Block) !void {
        const lastBlock = self.blocks.getLast();
        if (!std.mem.eql(u8, block.previous_hash[0..], lastBlock.hash[0..])) {
            return BlockchainError.InvalidBlock;
        }

        if (!isValidHash(block.hash)) {
            return BlockchainError.InvalidProofOfWork;
        }
    }
};

pub const Block = struct {
    previous_hash: std.ArrayList(u8),
    hash: std.ArrayList(u8),
    nonce: u64,
    transactions: std.ArrayList(Transaction),
};

fn proofOfWork(block: *Block) void {
    while (!isValidHash(block.hash)) {
        block.nonce += 1;
        block.hash = calculateHash(block);
    }
}

fn calculateHash(block: *Block) std.ArrayList(u8) {
    var s = std.ArrayList(u8).init(std.heap.page_allocator);
    defer s.deinit();

    s.appendSlice(block.previous_hash[0..]);
    for (block.transactions) |tx| {
        s.appendSlice(tx.sender[0..]);
        s.appendSlice(tx.receiver[0..]);
        s.appendSlice(std.mem.sliceAsBytes(&tx.amount));
    }
    s.appendSlice(std.mem.sliceAsBytes(&block.nonce));

    var hash: std.ArraList(u8) = undefined;
    Sha256.hash(s, hash, null);
    return hash;
}

pub fn isValidHash(hash: std.ArrayList(u8)) bool {
    var numLeadingZeros: u32 = 0;

    for (hash) |byte| {
        if (byte == 0) {
            numLeadingZeros += 8;
        } else {
            var mask: u8 = 0x80; // 1000 0000 in binary
            while (mask != 0 and (byte & mask) == 0) {
                numLeadingZeros += 1;
                mask >>= 1;
            }
            break;
        }

        if (numLeadingZeros >= NUM_LEADING_ZEROS_REQUIRED) break;
    }

    return numLeadingZeros >= NUM_LEADING_ZEROS_REQUIRED;
}

pub const Transaction = struct {
    sender: std.ArrayList(u8),
    receiver: std.ArrayList(u8),
    amount: u64,
    timestamp: u64,
};
