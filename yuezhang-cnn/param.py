import argparse


def get_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('--batch-size',      type=int,   default=64)
    parser.add_argument('--test-batch-size', type=int,   default=1000)
    parser.add_argument('--epochs',          type=int,   default=50)
    parser.add_argument('--lr',              type=float, default=1e-4)
    parser.add_argument('--gamma',           type=float, default=0.7, metavar='M',
                        help='Learning rate step gamma (default: 0.7)')
    parser.add_argument('--dry-run',         action='store_true', default=False,
                        help='quickly check a single pass')
    parser.add_argument('--log-interval',    type=int,   default=10,
                        help='how many batches to wait before logging training status')
    parser.add_argument('--seed', type=int, default=0)
    parser.add_argument('--save', action='store_true', default=False)
    return parser
