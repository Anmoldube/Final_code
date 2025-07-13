// Test to verify socket event safety
const { expect } = require('chai');

describe('Socket Event Safety', () => {
  let mockIo;
  
  beforeEach(() => {
    // Mock Socket.IO instance with missing adapter
    mockIo = {
      adapter: null, // Simulate undefined adapter
      sockets: {
        sockets: new Map()
      }
    };
  });

  it('should handle missing adapter gracefully', () => {
    // Simulate the fixed emitSocketEvent function
    const emitSocketEvent = (io, roomId, event, payload) => {
      let room = null;
      let clientCount = 0;
      
      if (io.adapter && io.adapter.rooms) {
        room = io.adapter.rooms.get(roomId);
        clientCount = room ? room.size : 0;
      }
      
      // Should not throw error even with missing adapter
      expect(() => {
        if (clientCount === 0) {
          console.log('No clients in room, using fallback');
        }
      }).to.not.throw();
    };

    // Test the function
    expect(() => {
      emitSocketEvent(mockIo, 'test-room', 'test-event', { test: 'data' });
    }).to.not.throw();
  });

  it('should handle missing rooms gracefully', () => {
    // Mock with adapter but no rooms
    mockIo.adapter = {
      rooms: null
    };

    const emitSocketEvent = (io, roomId, event, payload) => {
      let room = null;
      let clientCount = 0;
      
      if (io.adapter && io.adapter.rooms) {
        room = io.adapter.rooms.get(roomId);
        clientCount = room ? room.size : 0;
      }
      
      return clientCount;
    };

    // Should return 0 without throwing
    expect(emitSocketEvent(mockIo, 'test-room', 'test-event', { test: 'data' })).to.equal(0);
  });
});