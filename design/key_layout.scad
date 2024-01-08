include <BOSL2/std.scad>

$WIDTH_SWITCH_HOLE = 14;
$WIDTH_KEY_UNIT = 19.05;

$fn = 64;

function u(i) =
    assert(is_num(i))
    i * $WIDTH_KEY_UNIT;

// 数字列をR1として、R4を1Uあたり2°ずつカーブさせる。
// その他の行の1Uあたりのカーブ角度を一致させると中心側の行間隔が狭まりキー干渉の可能性がある。
// (円が縦にずれて重なる図をイメージするとわかりやすい)
// 各行の1Uあたりのカーブ角度を計算するには
// 1. R4のカーブ半径, 中心位置を求める
// 2. 各行のカーブ半径を求める
// 3. 同じ中心位置から各行のカーブ半径に対して1Uずつごとのカーブ角度を求める
//
// 1. R4のカーブ半径
// カーブ円の中心を頂点として底辺が1U(19.05), 頂角が2°, 底角が89°の二等辺三角形の斜辺の長さを求める
// 底辺がa, 斜辺がb, 底角がθとすると、a = 2 * b * cos(θ) → b = a / (2 * cos(θ))
radiusR4 = u(1) / (2 * cos(88));
//
// 2. 各行のカーブ半径を求める
// R1の半径 = radiusR4 + 3U
// R2の半径 = radiusR4 + 2U
// R3の半径 = radiusR4 + 1U
// R4の半径 = radiusR4
// R5の半径 = radiusR4 - 1U
function radius_row(n) = radiusR4 + u(4 - n);
//
// 2. 各行の1Uあたりのカーブ角度
// 各行の半径で1Uずつずらせる角度を求める
// カーブ円の中心を頂点として底辺が1U(19.05), 斜辺が各行の半径の二等辺三角形の頂角の角度を求める
// 底辺がa, 斜辺がb, 高さがh, 底角がθ, 頂角がφとすると
// h = sqrt(b^2 - (a^2 / 4)), θ = atan(2*h / a), φ = (90 - θ) * 2
function degrees_1u(rownum) = 
    let (
        a = u(1),
        b = radius_row(rownum),
        h = sqrt(pow(b, 2) - pow(a, 2) / 4),
        theta = atan(2 * h / a),
        phi = (90 - theta) * 2
    ) phi;

function key_next_origin(df, u) = 
    let (
        g = 0.25,
        lastOrigin = u <= 0 ? [0, 0] : key_next_origin(df, u - g),
        degrees = df(u),
        xy = u <= 0 ? [0, 0] : zrot(degrees, cp = lastOrigin, move(lastOrigin, [u(g), 0]))
    ) xy;

module layout(df = function(x) 0, units, transform, key_spin = 0, right_hand = false, offset = 0) {
    let (l = len(units))
    for (col = [0 : l - 1]) {
        let (
            w = u(units[col]),
            h = u(1),
            wh = false ? $WIDTH_SWITCH_HOLE : [w, h] - [1.05, 1.05],
            start = col == 0 ? offset : offset + sum(slice(units, 0, col - 1)),
            degrees = df(start + units[col] / 2),
            origin = key_next_origin(df, start),
            xy0 = rot(degrees, cp = origin, p = move(origin, [w/2, h/2])),
            xy = apply(transform, xy0),
            key_angle = (right_hand ? -1 : 1) * (degrees + key_spin)
        ) {
            echo(str("{\"x\":", xy.x, ",\"y\":", xy.y, ", \"deg\":", key_angle, "},"));
            move(xy)
            rect(wh, center = true, spin = key_angle, rounding = 1);
        }
    }
}

$DISTANCE = 1.5;

module left() {
    let (
        key_degree = function (r) function (u) max(u - 1.25, 0) * -degrees_1u(r),
        no_curve = function(_) 0,
        base_mat = left(u($DISTANCE + 8.5))
    ) {
        layout(key_degree(1), [1.00, 1, 1, 1, 1, 1, 1], base_mat * back(u(4)));
        layout(key_degree(2), [1.50, 1, 1, 1, 1, 1],    base_mat * back(u(3)));
        layout(key_degree(3), [1.75, 1, 1, 1, 1, 1],    base_mat * back(u(2)));
        layout(key_degree(4), [2.25, 1, 1, 1, 1, 1],    base_mat * back(u(1)));
        layout(key_degree(5), [1.50, 1, 1.50, 1.50],    base_mat * back(u(0)));

        let (
            o = key_next_origin(key_degree(4), 6.25),
            thumb_mat = base_mat * move([o.x, o.y, 0]) * zrot(-40, cp = [0, u(1)])
        ) {
            layout(no_curve, [1],    key_spin = -40, thumb_mat * back(u(1)) * right(u(1)));
            layout(no_curve, [1, 1], key_spin = -40, thumb_mat);
        }
    }
}

module right() {
    let (
        key_degree = function (r) function (u) max(u - 1.75, 0) * -degrees_1u(r),
        no_curve = function(_) 0,
        base_mat = right(u($DISTANCE + 9)) * xflip()
    ) {
        layout(key_degree(1), offset = 0.00, [1, 1, 1, 1, 1, 1, 1, 1], base_mat * back(u(4)), right_hand = true);
        layout(key_degree(2), offset = 0.50, [1, 1, 1, 1, 1, 1, 1],    base_mat * back(u(3)), right_hand = true);
        layout(key_degree(3), offset = 0.25, [1, 1, 1, 1, 1, 1, 1],    base_mat * back(u(2)), right_hand = true);
        layout(key_degree(4), offset = 0.75, [1, 1, 1, 1, 1, 1, 1],    base_mat * back(u(1)), right_hand = true);
        layout(key_degree(5), offset = 0.50, [1, 1.5, 1.5, 1.5],       base_mat * back(u(0)), right_hand = true);

        let (
            o = key_next_origin(key_degree(4), 6.75),
            thumb_mat = base_mat * move([o.x, o.y, 0]) * zrot(-40, cp = [0, u(1)])
        ) {
            layout(no_curve, [1],    key_spin = -40, thumb_mat * back(u(1)) * right(u(1)), right_hand = true);
            layout(no_curve, [1, 1], key_spin = -40, thumb_mat, right_hand = true);
        }

        let (
            origin = key_next_origin(key_degree(4), 8),
            ten_mat = base_mat * back(u(0.75)) * zrot(-15, cp = origin) * move([origin.x, origin.y, 0])
        ) {
            layout(no_curve, [1, 1, 1, 1],       key_spin = -15, ten_mat * back(u(4)), right_hand = true);
            layout(no_curve, [1, 1, 1, 1],       key_spin = -15, ten_mat * back(u(3)), right_hand = true);
            layout(no_curve, [1, 1, 1, 1],       key_spin = -15, ten_mat * back(u(2)), right_hand = true);
            layout(no_curve, [1, 1, 1, 1],       key_spin = -15, ten_mat * back(u(1)), right_hand = true);
            layout(no_curve, [1, 2], offset = 1, key_spin = -15, ten_mat * back(u(0)), right_hand = true);
        }
    }
}

left();
right();

color("pink") move([-39, 78]) rect([21, 21], center = true);
color("pink") move([0, 95]) rect([1000, 1], center = true);
