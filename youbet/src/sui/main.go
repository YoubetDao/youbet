package main

import (
	"context"

	"github.com/block-vision/sui-go-sdk/models"
	"github.com/block-vision/sui-go-sdk/sui"
	"github.com/block-vision/sui-go-sdk/signer"
	"log/slog"
)

var logger = slog.Default()

func main() {
	cli := sui.NewSuiClient("https://sui-testnet-endpoint.blockvision.org")
	signer, err := signer.NewSignertWithMnemonic("0x5d0ed262b481eb71dc1347f61194cf963b3e8327f02946b458dbec8046bde91b")
	if err != nil {
		logger.Error("failed to create signer", "error", err)
		return
	}

	cli.MoveCall(context.Background(), models.MoveCallRequest{
		Signer:          signer.Address,
		PackageObjectId: "0x7a638a2a2f7118c1d3b209fe14902a61c2b8eeb9f288681efc2f42a1a0308ec5",
		Module:          "distributor",
		Function:        "create_red_packet",
		TypeArguments:   []interface{}{"0x2::sui::SUI"},
		Arguments: []interface{}{
			"0x9f71893318fcec03377618948c39dd4e041aefdecadaf44220b1fac61c5addd2",
			"[114,101,100,112,97,99,107,101,116,48,48,49]",
			"[[104,97,119,107,108,105,45,49,57,57,52]]",
			"[100000000]",
			"0x5d0ed262b481eb71dc1347f61194cf963b3e8327f02946b458dbec8046bde91b",
		},
		GasBudget: "100000000",
	})
}

// sui client call \
// --package 0x7a638a2a2f7118c1d3b209fe14902a61c2b8eeb9f288681efc2f42a1a0308ec5 \
// --module distributor \
// --function create_red_packet \
// --type-args "0x2::sui::SUI" \
// --args \
//   "0x9f71893318fcec03377618948c39dd4e041aefdecadaf44220b1fac61c5addd2" \
//   "[114,101,100,112,97,99,107,101,116,48,48,49]" \
//   "[[104,97,119,107,108,105,45,49,57,57,52]]" \
//   "[100000000]" \
//   "0x5d0ed262b481eb71dc1347f61194cf963b3e8327f02946b458dbec8046bde91b" \
// --gas-budget 100000000 --json
