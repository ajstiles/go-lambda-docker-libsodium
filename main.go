package main

import (
	"context"
	"encoding/hex"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/jamesruan/sodium"
)

func HandleRequest(ctx context.Context) (string, error) {
	signKP := sodium.MakeSignKP()
	keyStr := hex.EncodeToString(signKP.SecretKey.Bytes)
	log.Print(keyStr)
	return keyStr, nil
}

func main() {
	lambda.Start(HandleRequest)
}
