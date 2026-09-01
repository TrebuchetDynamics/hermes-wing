//go:build !android

package app

import "context"

func startHermesGateway(
	ctx context.Context,
	_ string,
	_ string,
	run func(context.Context, ...string) error,
) error {
	for _, args := range hermesGatewayCommands() {
		if err := run(ctx, args...); err != nil {
			return err
		}
	}
	return nil
}

func restartHermesGateway(
	ctx context.Context,
	_ string,
	_ string,
	run func(context.Context, ...string) error,
) error {
	return run(ctx, "gateway", "restart")
}
