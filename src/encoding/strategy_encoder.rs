use anyhow::Error;

use crate::encoding::models::{ActionType, Solution};

#[allow(dead_code)]
pub trait StrategyEncoder {
    fn encode_strategy(&self, to_encode: Solution) -> Result<Vec<u8>, Error>;

    fn action_type(&self, exact_out: bool) -> ActionType;
    fn selector(&self, exact_out: bool) -> &str;
}

pub trait StrategySelector {
    #[allow(dead_code)]
    fn select_strategy(&self, solution: &Solution) -> Box<dyn StrategyEncoder>;
}
