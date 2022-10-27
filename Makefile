install:
	kubectl apply -f httpbin.yaml
	kubectl apply -f fortio.yaml

delay:
	kubectl apply -f delay-vs.yaml

500:
	kubectl apply -f 500-vs.yaml

bench:
	./bench.sh

benchroc:
	./bench-roc.sh
