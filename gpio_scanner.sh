#!/bin/bash

# 只测试可能的引脚范围 (0-15)
pins=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)

# 创建测试目录
mkdir -p test_builds

# 计数器
counter=1

echo "开始GPIO扫描测试..."
echo "只测试P0.00到P0.15的引脚组合"
echo "总共组合数: $(( ${#pins[@]} * ${#pins[@]} - ${#pins[@]} ))"

for a_pin in "${pins[@]}"; do
  for b_pin in "${pins[@]}"; do
    # 跳过无效组合
    if [ "$a_pin" -eq "$b_pin" ]; then continue; fi
    
    echo "测试组合 $counter: A=P0.$a_pin, B=P0.$b_pin"
    
    # 创建临时overlay文件
    cat > zmk/app/boards/shields/sofle/sofle.overlay << EOF
/dts-v1/;
/plugin/;

#include <dt-bindings/zmk/encoder.h>

/ {
  encoders {
    compatible = "zmk,encoders";
    test_encoder: test_encoder {
      compatible = "alps,ec11";
      a-gpios = <&gpio0 $a_pin (GPIO_ACTIVE_HIGH | GPIO_PULL_UP)>;
      b-gpios = <&gpio0 $b_pin (GPIO_ACTIVE_HIGH | GPIO_PULL_UP)>;
      steps = <4>; // 高灵敏度
    };
  };

  chosen {
    zmk,encoder-left = <&test_encoder>;
    zmk,encoder-map-left = <
      &inc_dec_kp LEFT RIGHT
    >;
  };
};
EOF
    
    # 构建固件
    west build -s zmk/app -b nice_nano_v2 -- -DSHIELD=sofle_left -DZMK_CONFIG="$(pwd)/config" --build-dir "test_builds/combo_$counter" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
      echo "固件构建成功: test_builds/combo_$counter/zephyr/zmk.uf2"
      echo "请刷写固件并测试:"
      echo "1. 顺时针旋转旋钮 - 应触发 RIGHT 键"
      echo "2. 逆时针旋转旋钮 - 应触发 LEFT 键"
      echo "3. 如果有效，记录引脚组合 A=$a_pin, B=$b_pin"
      echo "4. 按回车继续测试下一组"
      read
    else
      echo "构建失败，跳过此组合"
    fi
    
    ((counter++))
  done
done

echo "所有组合测试完成！"
