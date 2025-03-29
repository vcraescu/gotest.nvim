package ts

import "testing"

func TestSum(t *testing.T) {
	type args struct {
		a int
		b int
	}

	tests := []struct {
		name string
		args args
		want int
	}{
		{
			name: "success",
			args: args{a: 10, b: 10},
			want: 20,
		},
		{
			name: "fail",
			args: args{b: 10},
			want: 20,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := Sum(tt.args.a, tt.args.b); got != tt.want {
				t.Errorf("sum() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestSum2(t *testing.T) {
	t.Run("success", func(t *testing.T) {
		want := 30

		if got := Sum(10, 20); got != want {
			t.Errorf("sum() = %v, want %v", got, want)
		}
	})

	t.Run("fail", func(t *testing.T) {
		want := 20

		if got := Sum(10, 20); got != want {
			t.Errorf("sum() = %v, want %v", got, want)
		}
	})
}
