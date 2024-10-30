include "console.iol"

// Interface for calculator operations: addition and subtraction
interface CalculatorInterface {
    RequestResponse:
        add(AddRequest)(int), 
        subtract(SubtractRequest)(int) 
}

// Type definition for addition request with two integer operands
type AddRequest: void {
    x: int // First operand
    y: int // Second operand
}

// Type definition for subtraction request with two integer operands
type SubtractRequest: void {
    x: int // Minuend
    y: int // Subtrahend
}

// Service for handling calculator operations
service TargetService {
    execution: concurrent // Allows concurrent processing of requests
    
    // Input port for handling calculator requests, listening on localhost:8002
    inputPort TargetServicePort {
        Location: "socket://localhost:8002"
        Protocol: sodep
        Interfaces: CalculatorInterface
    }

    // Main service logic for handling addition and subtraction
    main {
        // Handle addition requests
        [ add(request)(response) {
            response = request.x + request.y // Perform addition and set the response
            println@Console("Handled add operation: " + request.x + " + " + request.y + " = " + response)() // Log the operation
        } ]

        // Handle subtraction requests
        [ subtract(request)(response) {
            response = request.x - request.y // Perform subtraction and set the response
            println@Console("Handled subtract operation: " + request.x + " - " + request.y + " = " + response)() // Log the operation
        } ]
    }
}