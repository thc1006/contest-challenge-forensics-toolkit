
.PHONY: case
case:
	@CASE=$(CASE); \
	if [ -z "$$CASE" ]; then echo "Usage: make case CASE=cases/xxx.yaml"; exit 1; fi; \
	bash scripts/run_case.sh $$CASE
