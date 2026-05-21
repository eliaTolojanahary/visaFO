package services;

public class ScanIncompleteException extends RuntimeException {
    public ScanIncompleteException(String message) {
        super(message);
    }
}