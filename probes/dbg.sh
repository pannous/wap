source "$(dirname "$0")/../test/wap/compile.sh"
ran d1 '+=(a: int, b: int): int := 99
i = 1
i += 1
i'
ran d2 'grow(xs: list<int>, more: list<int>): list<int> := { xs.extend(more); xs }
xs = [1]
ys = xs
xs = grow(xs, [2])
print ys'
