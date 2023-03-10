const std = @import("std");

const debug = std.debug;
const io = std.io;
const fs = std.fs;
const math = std.math;
const Allocator = std.mem.Allocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub fn main() !void {
    // allocate a large enough buffer to store the cwd
    var buf: [fs.MAX_PATH_BYTES]u8 = undefined;
    
    // getcwd writes the path of the cwd into buf and returns a slice of buf with the len of cwd
    const cwd = try std.os.getcwd(&buf);

    // print out the cwd
    debug.print("cwd: {s}\n", .{cwd}); 
    tokenize();
    listOfPeople();
    try arrayListUnmanaged();
    try jsonExample();
    try readJsonFileExample();
}

fn overFlow() void {
    // Integer overflow
    const x: u8 = 255;
    _ = x + 1;
}

fn tokenize() void {
    const msg = "hello this is dog";
    var it = std.mem.tokenize(u8, msg, " ");
    while (it.next()) |item| {
        std.debug.print("{s}\n", .{item});
    }
}

fn List(comptime T: type) type {
    return struct {
        items: []T,
        len: usize,
    };
}

const Person = struct { name: []const u8, age: u6 };

fn listOfPeople() void {
    var buffer: [2]Person = undefined;
    var list = List(Person){
        .items = &buffer,
        .len = 0,
    };

    std.debug.print("{d}\n", .{list.items.len});
}

fn arrayListUnmanaged() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var buffer = [_]Person{ Person{ .name = "Theo", .age = @as(u6, 38) }, Person{ .name = "Alex", .age = @as(u6, 39) } };
    var list = try ArrayListUnmanaged(Person).initCapacity(allocator, buffer.len);
    errdefer list.deinit(allocator);
    list.appendSliceAssumeCapacity(&buffer);

    for (list.items) |p| {
        debug.print("Your name is: \"{s}\" and your age is \"{d}\"\n", .{ p.name, p.age });
    }
}

const Data = struct { people: []Person };

fn jsonExample() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer std.debug.assert(!gpa.deinit()); // no leaks
    const s =
        \\ {
        \\   "people": [{"name":"Theo", "age": 38}, {"name":"Alex", "age": 40}]
        \\ }
    ;
    var stream = std.json.TokenStream.init(s);
    const parsedData = try std.json.parse(Data, &stream, .{
        .allocator = allocator
    });
    defer std.json.parseFree(Data, parsedData, .{ .allocator = allocator });
    for (parsedData.people) |p| {
        debug.print("Your name is: \"{s}\" and your age is \"{d}\"\n", .{ p.name, p.age });
    }
}

fn readJsonFileExample() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const parsedData = try readData(allocator, "/Users/theo.despoudis/Workspace/zig-sink/example.json");
    defer std.json.parseFree(Data, parsedData, .{ .allocator = allocator });

    for (parsedData.people) |p| {
        debug.print("Your name is: \"{s}\" and your age is \"{d}\"\n", .{ p.name, p.age });
    }
}

fn readData(allocator: Allocator, path: []const u8) !Data {
  const data = try readFile(allocator, path);
  defer allocator.free(data);

  // these 2 new lines
  var stream = std.json.TokenStream.init(data);

  // 3rd parameter is a ParseOption. Zig can infer the type. The explicit version
  // would be std.json.ParseOption{.allocator = allocator}
  return try std.json.parse(Data, &stream, .{.allocator = allocator});
}

fn readFile(allocator: Allocator, path: []const u8) ![]const u8 {
    var file: fs.File = undefined;
    file = try fs.openFileAbsolute(path, .{ });
    defer file.close();

    const size_limit = math.maxInt(u32);
    var result = try file.readToEndAlloc(allocator, size_limit);
    return result;
}